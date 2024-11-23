//
//  ScrollStyleView.swift
//  EL-UI
//
//  Created by WJR on 3/28/24.
//

import SwiftUI
import PDFKit

struct ScrollShowView: View {
  private let triggerLoadNumber = 5 // How many items from the edge should trigger loading
  
  //@Binding var viewContent: ViewContent
  
  @Binding var showMenu: Bool
  
  @Binding var bookName: String
  @Binding var chapterNow: Int
  
  //@State var selectedPageId: Int?
  //@State var selectedWordIndex: Int = Int()
  
  @State var currentPageIndex: Int = 0
  @State var selectedWordIndex: Int = 0
  
  @State var pdfContent: PDFContent = PDFContent(pdf: PDFDocument(), contents: [])
  
  //@State var pgInfoContent = RPInfoContent()
  
  //  @StateObject var CL = RP_ContentLoader()
  //@StateObject var VO = RP_ViewObserver()
  
  // Add a timer property
  @State private var scrollDebounceTimer: Timer?
  
  // Modified onPageChanged callback
  func onPageChanged(pageIndex: Int) {
    print("changed")
    self.currentPageIndex = pageIndex
    
    // Cancel the previous timer
    scrollDebounceTimer?.invalidate()
    
    // Create a new timer to run after a delay
    scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
      PDFGenerator.shared.prioritizePageProcessing(pdfContent: pdfContent, pageIndex: pageIndex, chapterNow: chapterNow)
      print("start")
    }
  }
  
  // Single-tap handler: calls `wordChoosing` with the page index and the percentage position
  func handleSingleTap(pageIndex: Int, percentPosition: CGPoint) {
    print(pageIndex)
    selectedWordIndex = pageIndex
    wordChoosing(selectedPageIndex: selectedWordIndex, location: percentPosition, edit: false)
  }
  
  // Double-tap handler
  func handleDoubleTap(pageIndex: Int, percentPosition: CGPoint) {
    selectedWordIndex = pageIndex
    wordChoosing(selectedPageIndex: selectedWordIndex, location: percentPosition, edit: true)
  }
  
  /*
  // Convert the percentage position into actual coordinates on the page
  func convertPercentPositionToPageLocation(percentPosition: CGPoint, pageIndex: Int) -> CGPoint {
    guard let page = pdfContent.pdf.page(at: pageIndex) else { return .zero }
    let pageSize = page.bounds(for: .mediaBox).size
    return CGPoint(x: percentPosition.x * pageSize.width, y: percentPosition.y * pageSize.height)
  }
   */
  
  var body: some View {
    ZStack {
      PDFViewWrapper(
        pdfDocument: $pdfContent.pdf,
        onSingleTap: handleSingleTap,
        onDoubleTap: handleDoubleTap,
        onPageChanged: onPageChanged
      )
      .onAppear {
        NotificationCenter.default.addObserver(forName: .didAddNewPDFPage, object: nil, queue: .main) { _ in
          self.pdfContent = PDFGenerator.shared.pdfContent
        }
        
        self.pdfContent = PDFGenerator.shared.createInitialPDF(bookName: bookName, chapter: chapterNow)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea()
      
      VStack {
        if !showMenu {
          WordsShowingView(bookName: bookName, selectedPageIndex: $currentPageIndex, selectedWordIndex: $selectedWordIndex, pdfContents: $pdfContent)
            .transition(.move(edge: .bottom))
        }
      }
    }
  }
}

struct PDFViewWrapper: UIViewRepresentable {
  @Binding var pdfDocument: PDFDocument
  var onSingleTap: (Int, CGPoint) -> Void
  var onDoubleTap: (Int, CGPoint) -> Void
  var onPageChanged: ((Int) -> Void)
  
  func makeUIView(context: Context) -> PDFKit.PDFView {
    let pdfView = CustomPDFView()
    pdfView.autoScales = true
    pdfView.displayMode = .singlePageContinuous
    pdfView.displayDirection = .vertical
    pdfView.document = pdfDocument
    
    pdfView.singleTapAction = onSingleTap
    pdfView.doubleTapAction = onDoubleTap
    pdfView.currentPageIndexChanged = onPageChanged
    
    return pdfView
  }
  
  func updateUIView(_ pdfView: PDFKit.PDFView, context: Context) {
    pdfView.document = pdfDocument
  }
}



class CustomPDFView: PDFKit.PDFView {
  var singleTapAction: ((Int, CGPoint) -> Void)?
  var doubleTapAction: ((Int, CGPoint) -> Void)?
  var currentPageIndexChanged: ((Int) -> Void)?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  private func setup() {
    NotificationCenter.default.addObserver(self, selector: #selector(pageChanged), name: .PDFViewPageChanged, object: self)
    
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
    singleTapGesture.numberOfTapsRequired = 1
    singleTapGesture.require(toFail: addDoubleTapGesture())
    addGestureRecognizer(singleTapGesture)
  }
  
  private func addDoubleTapGesture() -> UITapGestureRecognizer {
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    addGestureRecognizer(doubleTapGesture)
    return doubleTapGesture
  }
  
  @objc private func handleSingleTap(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: self)
    if let page = self.page(for: location, nearest: true),
       let pageIndex = self.document?.index(for: page) {
      
      let pageLocation = self.convert(location, to: page)
      let percentPosition = CGPoint(x: pageLocation.x / page.bounds(for: .mediaBox).width,
                                    y: 1.0 - (pageLocation.y / page.bounds(for: .mediaBox).height))
      
      singleTapAction?(pageIndex, percentPosition)
    }
  }
  
  @objc private func handleDoubleTap(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: self)
    if let page = self.page(for: location, nearest: true),
       let pageIndex = self.document?.index(for: page) {
      
      let pageLocation = self.convert(location, to: page)
      let percentPosition = CGPoint(x: pageLocation.x / page.bounds(for: .mediaBox).width,
                                    y: 1.0 - (pageLocation.y / page.bounds(for: .mediaBox).height))
      
      doubleTapAction?(pageIndex, percentPosition)
    }
  }
  
  @objc private func pageChanged() {
    if let page = self.currentPage, let pageIndex = self.document?.index(for: page) {
      print("Current page changed to index: \(pageIndex)")
      currentPageIndexChanged?(pageIndex)
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: .PDFViewPageChanged, object: self)
  }
}

extension Notification.Name {
  static let didAddNewPDFPage = Notification.Name("didAddNewPDFPage")
}

extension ScrollShowView {
  func wordChoosing(selectedPageIndex: Int, location: CGPoint, edit: Bool) {
    print("wordChoosing called with location: \(location), edit: \(edit)")
    
    guard var textContent = pdfContent.contents[selectedPageIndex].textContent else {
      print("No textContent found for page \(selectedPageIndex)")
      return
    }
    
    var positions = textContent.positions

    if !edit {
      positions = textContent.unknownWordsIndex?.map { textContent.positions![$0] }
    }
    
    guard let closestIndex = DataAnalysis.findNearestWordIndex(location: location, quadrilateralArrays: positions!)?.section else {
      print("No nearest word index found")
      return
    }
    
    print("Nearest word index found: \(closestIndex)")

    if edit {
      selectedWordIndex = closestIndex
    } else {
      selectedWordIndex = textContent.unknownWordsIndex![closestIndex]
    }
    
    let selectedWord = textContent.texts![selectedWordIndex]
    print(selectedWord)
    
    if edit {
      if !textContent.unknownWordsIndex!.contains(closestIndex) {
        // Add the new unknown word index and add a highlight annotation
        textContent.unknownWordsIndex!.append(closestIndex)
        PDFProcessing().updateAnnotationForQuadrilateral(pdfDocument: pdfContent.pdf, pageIndex: selectedPageIndex, quadrilaterals: positions![closestIndex], shouldAdd: true)
        
        DispatchQueue.global(qos: .userInitiated).async {
          let word = Lemmatization().morphy(words: [textContent.texts![closestIndex]])
          LearedWordsDatabase().remove([word[0]])
        }
        print(textContent.texts![closestIndex])
      } else {
        // If the word is already in the unknown words list, remove the annotation
        PDFProcessing().updateAnnotationForQuadrilateral(pdfDocument: pdfContent.pdf, pageIndex: selectedPageIndex, quadrilaterals: positions![closestIndex], shouldAdd: false)
        
        if let wordIndexes = textContent.indexed?[selectedWord.texts.lowercased()] {
          for wordIndex in wordIndexes {
            if let removeIndex = textContent.unknownWordsIndex?.firstIndex(of: wordIndex) {
              textContent.unknownWordsIndex?.remove(at: removeIndex)
            }
            if let removeIndex = textContent.learningWordsIndex?.firstIndex(of: wordIndex) {
              textContent.learningWordsIndex?.remove(at: removeIndex)
            }
          }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
          for (index, pageContent) in pdfContent.contents.enumerated() {
            guard let innerTextContent = pdfContent.contents[index].textContent else { continue }
            if let wordIndexes = innerTextContent.indexed?[selectedWord.texts.lowercased()] {
              for wordIndex in wordIndexes {
                if let removeIndex = innerTextContent.unknownWordsIndex?.firstIndex(of: wordIndex) {
                  pdfContent.contents[index].textContent?.unknownWordsIndex?.remove(at: removeIndex)
                }
                if let removeIndex = innerTextContent.learningWordsIndex?.firstIndex(of: wordIndex) {
                  pdfContent.contents[index].textContent?.learningWordsIndex?.remove(at: removeIndex)
                }
              }
            }
          }
          
          UnknowWordsDatabase().remove(words: [selectedWord.texts.lowercased()])
          
          let word = Lemmatization().morphy(words: [textContent.texts![closestIndex]])
          LearedWordsDatabase().add(word)
        }
      }
      print(textContent.texts![closestIndex])
      // Write `textContent` back to `pdfContent.contents`
      pdfContent.contents[selectedPageIndex].textContent = textContent
      textContent.unknownWordsIndex?.sort()
      print(textContent.unknownWordsIndex ?? [])
    }
  }
}

/*
ScrollView([.vertical, .horizontal]) {
  ScrollViewReader { scrollView in
    ZStack(alignment: .center) {
      Rectangle()
        .fill(.clear)
        .frame(width: UIScreen.main.bounds.width * VO.scale)
      
      LazyVStack(spacing: 0) {
        ForEach(CL.ids, id: \.self) { id in
          // Attempt to find the view content by ID
          if let content = CL.contents.first(where: { $0.id == id }),
             let viewContent = content.viewContent {
            
            Image(uiImage: viewContent.showImage!)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .onAppear {
                appearProcessing(id: id)
              }
              .onDisappear {
                disappearProcessing(id: id)
              }
              .onTapGesture(count: 2, coordinateSpace: .local) { point in
                wordChoosing(id: id, point: point, edit: true)
              }
              .onTapGesture(count: 1, coordinateSpace: .local) { point in
                wordChoosing(id: id, point: point, edit: false)
              }
              .gesture(
                LongPressGesture(minimumDuration: 0.5)
                  .onEnded { _ in
                    withAnimation {
                      self.showMenu.toggle()
                    }
                  }
              )
              .background {
                GeometryReader { geo in
                  Color.clear
                    .onAppear {
                      VO.sizes[id] = geo.size
                    }
                    .onChange(of: geo.size) { newSize in
                      VO.sizes[id] = newSize
                    }
                }
              }
          } else {
            // Display a loading placeholder if image is not available
            LoadingView()
              .onAppear {
                CL.bookName = bookName
                CL.doubleDirectionsLoadViewContent(for: id) {}
              }
          }
        }
      }
      .frame(width: UIScreen.main.bounds.width)
      .onAppear {
        scrollView.scrollTo(1, anchor: .top)
      }
    }
  }
}
 .scaleEffect(VO.scale, anchor: .center)
 .simultaneousGesture(magnification)
 .onAppear {
   UIScrollView.appearance().bounces = false
 }
 
VStack {
  if !showMenu {
    WordsShowingView(bookName: bookName, selectedPageId: selectedPageId, selectedWordIndex: $selectedWordIndex, CL: CL, VO: VO)
      .transition(.move(edge: .bottom))
  }
}
*/

/*
extension ScrollShowView {
  func appearProcessing(id: Int) {
    VO.shouldPerformDelayedTask[id] = true
    VO.appearedPageIds.append(id)
    
    CL.bookName = bookName
    // Get the index of the current image
    if let index: Int = CL.contents.firstIndex(where: { $0.id == id}) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if VO.shouldPerformDelayedTask[id] ?? false {
          CL.loadInformation(for: id) {}
        }
        VO.shouldPerformDelayedTask.removeValue(forKey: id)
      }
      // Check if we need to load more content based on scroll position
      if index < triggerLoadNumber - 1 {
        // User has scrolled near the top, load previous content
        CL.loadMoreViewContent(direction: .previous)
      } else if index > CL.contents.count - triggerLoadNumber {
        // User has scrolled near the bottom, load next content
        CL.loadMoreViewContent(direction: .next)
      }
    }
  }
  
  func disappearProcessing(id: Int) {
    VO.shouldPerformDelayedTask[id] = false
    VO.sizes.removeValue(forKey: id)
    if let index = VO.appearedPageIds.firstIndex(of: id) {
      VO.appearedPageIds.remove(at: index)
      selectedPageId = VO.appearedPageIds.first
    }
  }
  
  var magnification: some Gesture {
    MagnificationGesture()
      .onChanged { val in
        print(val)
        let delta = val / VO.previousScale
        VO.previousScale = val
        let newScale = VO.scale * delta
        
        if newScale < 1.0 {
          VO.scale = 1.0
        } else if newScale > 2.0 {
          VO.scale = 2.0
        } else {
          VO.scale = newScale
          VO.scale = newScale
        }
      }.onEnded { val in
        VO.previousScale = 1.0
      }
  }
  
  func wordChoosing(id: Int, point: CGPoint, edit: Bool) {
    if let size = VO.sizes[id] {
      let location = CGPoint(x: point.x / size.width, y: point.y / size.height)
      print(location)
      if let selectedPageIndex = CL.contents.firstIndex(where: {$0.id == id}),
         let selectedtextContent = CL.contents[selectedPageIndex].textContent {
        
        var positions = selectedtextContent.positions
        if !edit {
          positions = selectedtextContent.unknownWordsIndex!.map{selectedtextContent.positions![$0]}
        }
        
        var minDistance: CGFloat = 999
        var minIndex: Int?
        
        for (index, wordPositions) in positions!.enumerated() {
          for wordPosition in wordPositions {
            let distance = sqrt(pow((wordPosition.topLeft.x + wordPosition.topRight.x) / 2 - location.x, 2) + pow((wordPosition.topLeft.y + wordPosition.bottomLeft.y) / 2 - location.y, 2))
            
            if distance < minDistance {
              minDistance = distance
              minIndex = index
            }
          }
        }
        
        if let closestIndex = minIndex {
          if edit {
            selectedWordIndex = closestIndex
          } else {
            print(selectedtextContent.unknownWordsIndex!)
            selectedWordIndex = selectedtextContent.unknownWordsIndex![closestIndex]
          }
          selectedPageId = id
          
          let selectedWord: String = selectedtextContent.texts![selectedWordIndex].texts
          
          if edit {
            if !selectedtextContent.unknownWordsIndex!.contains(closestIndex) {
              CL.contents[selectedPageIndex].textContent?.unknownWordsIndex!.append(closestIndex)
              
              DispatchQueue.global(qos: .userInitiated).async {
                let word = Lemmatization().morphy(words: [selectedtextContent.texts![closestIndex]])
                LearedWordsDatabase().remove([word[0]])
              }
            } else {
              if let wordIndexes = selectedtextContent.indexed![selectedWord.lowercased()] {
                for wordIndex in wordIndexes {
                  print(wordIndex)
                  if let removeIndex = CL.contents[selectedPageIndex].textContent?.unknownWordsIndex!.firstIndex(of: wordIndex) {
                    CL.contents[selectedPageIndex].textContent?.unknownWordsIndex!.remove(at: removeIndex)
                  }
                  if let removeIndex = CL.contents[selectedPageIndex].textContent?.learningWordsIndex!.firstIndex(of: wordIndex) {
                    CL.contents[selectedPageIndex].textContent?.learningWordsIndex!.remove(at: removeIndex)
                  }
                }
              }
              
              DispatchQueue.global(qos: .userInitiated).async {
                for pageId in VO.appearedPageIds {
                  if let pageIndex = CL.contents.firstIndex(where: {$0.id == pageId}),
                     let textContent = CL.contents[pageIndex].textContent,
                     let wordIndexes = textContent.indexed![selectedWord.lowercased()] {
                    for wordIndex in wordIndexes {
                      if let removeIndex = CL.contents[pageIndex].textContent?.unknownWordsIndex!.firstIndex(of: wordIndex) {
                        CL.contents[pageIndex].textContent?.unknownWordsIndex!.remove(at: removeIndex)
                      }
                      if let removeIndex = CL.contents[pageIndex].textContent?.learningWordsIndex!.firstIndex(of: wordIndex) {
                        CL.contents[pageIndex].textContent?.learningWordsIndex!.remove(at: removeIndex)
                      }
                    }
                  }
                }
                
                
                UnknowWordsDatabase().remove(words: [selectedWord.lowercased()])
                
                let word = Lemmatization().morphy(words: [selectedtextContent.texts![closestIndex]])
                LearedWordsDatabase().add(word)
              }
            }
            CL.contents[selectedPageIndex].textContent!.unknownWordsIndex!.sort()
            
            print(CL.contents[selectedPageIndex].textContent!.unknownWordsIndex!)
            
            DispatchQueue.global(qos: .userInitiated).async {
              let newImage = ImageProcessing().drawQuadrilateralsOnImage(pageInformation: CL.contents[selectedPageIndex].textContent!, baseImage: CL.contents[selectedPageIndex].viewContent!.originalImage!)
              DispatchQueue.main.async {
                CL.contents[selectedPageIndex].viewContent?.showImage = newImage
              }
            }
          }
        }
      }
    }
  }
}
 */
