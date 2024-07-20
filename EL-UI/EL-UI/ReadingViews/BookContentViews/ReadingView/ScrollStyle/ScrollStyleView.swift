//
//  ScrollStyleView.swift
//  EL-UI
//
//  Created by WJR on 3/28/24.
//

import SwiftUI

struct ScrollShowView: View {
  private let triggerLoadNumber = 5 // How many items from the edge should trigger loading
  
  @Binding var bookName: String
  @Binding var viewContent: ViewContent
  
  @Binding var showMenu: Bool
  
  @State var selectedPageId: Int?
  @State var selectedWordIndex: Int = Int()
  
  @StateObject var CL = RP_ContentLoader()
  @StateObject var VO = RP_ViewObserver()
  
  var body: some View {
    if !CL.contents.isEmpty {
      ZStack {
        
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
        WordsShowingView(bookName: bookName, selectedPageId: selectedPageId, selectedWordIndex: $selectedWordIndex, CL: CL, VO: VO)
        
      }
    } else {
      LoadingView()
        .onAppear {
          CL.bookName = bookName
          CL.loadInitialContent() { isEmpty in
            if isEmpty {
              viewContent = .reading(.bookEdit)
            }
          }
          
        }
    }
  }
}

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
