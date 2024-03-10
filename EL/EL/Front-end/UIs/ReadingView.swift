//
//  ReadingView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

struct ReadingView: View {
  let screen = UIScreen.main.bounds.size
  
  @Binding var bookName: String
  @Binding var pageIndex: Int
  
  @Binding var image: UIImage
  @Binding var result: PictureShowPage
  
  @Binding var showImage: Bool
  @Binding var showResult: Bool

  @State private var showingImage: UIImage?
  @State private var showDefinitionSheet = false
  @State private var selectedWord: Word?
  
  @State private var selectedTabIndex = 0
  
  @State private var scaleFactor: CGFloat = 1.0
  @State private var pictureRealSize: CGSize = .zero
  
  @State private var zoom: CGFloat = 1.0
  @State private var previousZoom: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var previousOffset: CGSize = .zero
  
  @State private var showSheet = false
  
  var body: some View {
    VStack(spacing: 0) {
      Button("Show Words") {
        self.showSheet = true
      }
      
      if showImage {
        Image(uiImage: showResult ? showingImage ?? image : image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .offset(offset)
          .scaleEffect(zoom)
          .overlay(
            GeometryReader { geometry in
              
              Color.white.opacity(0.0000001)
                .onTapGesture(count: 2) { value in
                  handleDoubleTapGesture(value: value, geometry: geometry)
                }
                .onTapGesture(count: 1) { value in
                  handleSingleTapGesture(value: value, geometry: geometry)
                }
                .simultaneousGesture(
                  scaleShiftGesture(zoom: $zoom,
                                    previousZoom: $previousZoom,
                                    offset: $offset,
                                    previousOffset: $previousOffset)
                )
            }
          )
          .mask {
            Rectangle()
          }
          .frame(width: pictureRealSize.width)
          .ignoresSafeArea(.all)
          .onAppear {
            valueInitialize()
          }
        
        Spacer(minLength: 0)
        
        if showResult {
          TabView(selection: $selectedTabIndex) {
            ForEach(result.unknowWordsIndex ?? [], id: \.self) { index in
              WordCardView(result: $result, index: index, bookName: bookName, pageIndex: pageIndex)
                .tag(index)
            }
          }
          .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
          .frame(height: 90)
          .onAppear {
            showingImage = drawQuadrilateralsOnImage(pageInformation: result, baseImage: image)
          }
        }
      }
    }
    .sheet(isPresented: $showSheet) {
      WordsSheetView(bookName: bookName)
    }
  }
}

struct WordCardView: View {
  @Binding var result: PictureShowPage
  var index: Int
  
  var bookName: String
  var pageIndex: Int
  
  var body: some View {
    HStack(alignment: .top) {
      if let word = result.texts?[index],
         let learningWordsIndex = result.learningWordsIndex {
        
        Text(word.texts)
          .font(.system(size: 15))
          .fontWeight(.bold)
          .foregroundColor(Color.blue)
        
        Divider()
        
        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: 5) {
            ForEach(result.definitionForWord(at: index), id: \.self) { definition in
              Text(definition)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }
          }
        }
        
        Spacer(minLength: 0)
        
        let learning = learningWordsIndex.contains(index)
        Button(action: {
          print(learning)
          print(index)
          if learning {
            result.learningWordsIndex?.remove(at: (result.learningWordsIndex?.firstIndex(of: index))!)
            DispatchQueue.global(qos: .userInitiated).async {
              UnknowWordsDatabase().remove(words: [word.texts])
            }
          } else {
            result.learningWordsIndex?.append(index)
            DispatchQueue.global(qos: .userInitiated).async {
              print(word.texts)
              UnknowWordsDatabase().add(words: [word.texts], bookIndex: bookName, pageIndex: pageIndex)
            }
          }
        }) {
          Image(systemName: learning ? "star.fill" : "star")
        }
      }
    }
    .padding()
    .border(Color.white)
    .cornerRadius(15)
    .frame(width: 300, height: 90)
    .shadow(color: .white.opacity(0.5), radius: 5, x: 0, y: 2)
    
  }
}

struct WordsSheetView: View {
  var bookName: String
  @State private var words: [String] = []
  
  var body: some View {
    if !words.isEmpty {
      List {
        ForEach(0..<words.count, id: \.self) { i in
          Text(words[i])
        }
        .onDelete(perform: { indexs in
          if let index = indexs.first {
            UnknowWordsDatabase().remove(words: [words[index]])
          }
        })
      }
      .navigationBarTitle("Words", displayMode: .inline)
      .toolbar {
        Button("Done") {
        }
      }
    } else {
      LoadingView()
        .onAppear {
          words = UnknowWordsDatabase().showAllWords()
        }
    }
  }
}

extension ReadingView {
  private func pictrueSides(pRS: CGSize, zoom: CGFloat, newOffset: CGSize) -> CGSize {
    let maxWidthOffset = pRS.width / 2 * (zoom - 1) / zoom
    let maxHeightOffset = pRS.height / 2 * (zoom - 1) / zoom
    
    let newWidth = min(max(newOffset.width, -maxWidthOffset), maxWidthOffset)
    let newHeight = min(max(newOffset.height, -maxHeightOffset), maxHeightOffset)
    return CGSize(width: newWidth, height: newHeight)
  }
  
  func distance(_ location: CGPoint, _ previousLocation: CGPoint) -> CGFloat {
    let xD = location.x - previousLocation.x
    let yD = location.y - previousLocation.y
    let distance = sqrt(pow(xD, 2) + pow(yD, 2))
    return distance
  }
  
  private func valueInitialize() {
    scaleFactor = screen.width / (showingImage ?? image).size.width
    pictureRealSize = CGSize(width: (showingImage ?? image).size.width * scaleFactor,
                             height: (showingImage ?? image).size.height * scaleFactor)
    zoom = 1.0
    previousZoom = 1.0
    offset = CGSize.zero
    previousOffset = CGSize.zero
  }
  
  private func handleDoubleTapGesture(value: CGPoint, geometry: GeometryProxy) {
    let pictureFrame = geometry.frame(in: .local)
    
    let tapPosition = CGPoint(x: (pictureFrame.midX * zoom - pictureFrame.midX + value.x) / zoom - offset.width,
                              y: (pictureFrame.midY * zoom - pictureFrame.midY + value.y) / zoom - offset.height)
    
    if let positions = result.positions {
      var minDistance: CGFloat = 999
      var minIndex: Int?
      
      for (index, wordPositions) in positions.enumerated() {
        for p in wordPositions {
          let centerX = (p.topLeft.x + p.topRight.x + p.bottomLeft.x + p.bottomRight.x) / 4 * geometry.size.height
          let centerY = (p.topLeft.y + p.topRight.y + p.bottomLeft.y + p.bottomRight.y) / 4 * geometry.size.height
          let distance = sqrt(pow(centerX - tapPosition.x, 2) + pow(centerY - tapPosition.y, 2))
          
          if distance < minDistance {
            minDistance = distance
            minIndex = index
          }
        }
      }
      
      if let closestIndex = minIndex {
        if result.unknowWordsIndex!.contains(closestIndex) {
          result.unknowWordsIndex!.remove(at: result.unknowWordsIndex!.firstIndex(of: closestIndex)!)
          
          DispatchQueue.global(qos: .userInitiated).async {
            let word = Lemmatization().morphy(words: [result.texts![closestIndex]])
            LearedWordsDatabase().add(word)
          }
        }
        
        result.unknowWordsIndex!.sort()
        showingImage = drawQuadrilateralsOnImage(pageInformation: result, baseImage: image)
      }
    }
  }
  
  private func handleSingleTapGesture(value: CGPoint, geometry: GeometryProxy) {
    let pictureFrame = geometry.frame(in: .local)
    
    let tapPosition = CGPoint(x: (pictureFrame.midX * zoom - pictureFrame.midX + value.x) / zoom - offset.width,
                              y: (pictureFrame.midY * zoom - pictureFrame.midY + value.y) / zoom - offset.height)
    
    if let positions = result.positions {
      var minDistance: CGFloat = 999
      var minIndex: Int?
      
      for (index, wordPositions) in positions.enumerated() {
        for p in wordPositions {
          let centerX = (p.topLeft.x + p.topRight.x + p.bottomLeft.x + p.bottomRight.x) / 4 * geometry.size.height
          let centerY = (p.topLeft.y + p.topRight.y + p.bottomLeft.y + p.bottomRight.y) / 4 * geometry.size.height
          let distance = sqrt(pow(centerX - tapPosition.x, 2) + pow(centerY - tapPosition.y, 2))
          
          if distance < minDistance {
            minDistance = distance
            minIndex = index
          }
        }
      }
      
      if let closestIndex = minIndex {
        if !result.unknowWordsIndex!.contains(closestIndex) {
          result.unknowWordsIndex!.append(closestIndex)
          
          DispatchQueue.global(qos: .userInitiated).async {
            let word = Lemmatization().morphy(words: [result.texts![closestIndex]])
            LearedWordsDatabase().remove([word[0]])
          }
        }
        result.unknowWordsIndex!.sort()
        showingImage = drawQuadrilateralsOnImage(pageInformation: result, baseImage: image)
        
        selectedTabIndex = closestIndex
      }
    }
  }
  
  func scaleShiftGesture(zoom: Binding<CGFloat>,
                         previousZoom: Binding<CGFloat>,
                         offset: Binding<CGSize>,
                         previousOffset: Binding<CGSize>) -> some Gesture {
    
    let magnificationGesture = MagnificationGesture(minimumScaleDelta: 0)
      .onChanged { value in
        let delta = value / previousZoom.wrappedValue
        previousZoom.wrappedValue = value
        if zoom.wrappedValue * delta >= 1.0 {
          zoom.wrappedValue *= delta
        } else {
          zoom.wrappedValue = 1.0
        }
      }
      .onEnded { value in
        previousZoom.wrappedValue = 1.0
        withAnimation {
          offset.wrappedValue = pictrueSides(pRS: pictureRealSize,
                                             zoom: zoom.wrappedValue,
                                             newOffset: offset.wrappedValue)
        }
      }
    
    let dragGesture = DragGesture(minimumDistance: 0)
      .onChanged { value in
        let translation = CGSize(
          width: value.translation.width / zoom.wrappedValue,
          height: value.translation.height / zoom.wrappedValue
        )
        offset.wrappedValue = pictrueSides(pRS: pictureRealSize,
                                           zoom: zoom.wrappedValue,
                                           newOffset: CGSize(width: previousOffset.wrappedValue.width + translation.width,
                                                             height: previousOffset.wrappedValue.height + translation.height))
      }
      .onEnded { value in
        previousOffset.wrappedValue = offset.wrappedValue
      }
    
    return magnificationGesture.simultaneously(with: dragGesture)
  }
}

private func drawQuadrilateralsOnImage(pageInformation: PictureShowPage, baseImage: UIImage) -> UIImage {
  let renderer = UIGraphicsImageRenderer(size: baseImage.size)
  let renderedImage = renderer.image { context in
    baseImage.draw(at: .zero)
    
    let strokeColor = UIColor.red
    
    if let positions = pageInformation.positions {
      let unknowWordsIndex = pageInformation.unknowWordsIndex!
      for (index, wordQuadrilaterals) in positions.enumerated() {
        if unknowWordsIndex.contains(index) {
          if wordQuadrilaterals.count == 1 {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: wordQuadrilaterals[0].topLeft.x * baseImage.size.height,
                                  y: wordQuadrilaterals[0].topLeft.y * baseImage.size.height))
            path.addLine(to: CGPoint(x: wordQuadrilaterals[0].topRight.x * baseImage.size.height,
                                     y: wordQuadrilaterals[0].topRight.y * baseImage.size.height))
            path.addLine(to: CGPoint(x: wordQuadrilaterals[0].bottomRight.x * baseImage.size.height,
                                     y: wordQuadrilaterals[0].bottomRight.y * baseImage.size.height))
            path.addLine(to: CGPoint(x: wordQuadrilaterals[0].bottomLeft.x * baseImage.size.height,
                                     y: wordQuadrilaterals[0].bottomLeft.y * baseImage.size.height))
            path.close()
            
            strokeColor.setStroke()
            path.stroke()
          } else {
            for (partIndex, quadrilateral) in wordQuadrilaterals.enumerated() {
              let path = UIBezierPath()
              if partIndex == 0 {
                path.move(to: CGPoint(x: quadrilateral.topRight.x * baseImage.size.height,
                                      y: quadrilateral.topRight.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: quadrilateral.topLeft.x * baseImage.size.height,
                                         y: quadrilateral.topLeft.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: quadrilateral.bottomLeft.x * baseImage.size.height,
                                         y: quadrilateral.bottomLeft.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: quadrilateral.bottomRight.x * baseImage.size.height,
                                         y: quadrilateral.bottomRight.y * baseImage.size.height))
              } else if partIndex == wordQuadrilaterals.count - 1 {
                path.move(to: CGPoint(x: quadrilateral.topLeft.x * baseImage.size.height,
                                      y: quadrilateral.topLeft.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: quadrilateral.topRight.x * baseImage.size.height,
                                         y: quadrilateral.topRight.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: quadrilateral.bottomRight.x * baseImage.size.height,
                                         y: quadrilateral.bottomRight.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: quadrilateral.bottomLeft.x * baseImage.size.height,
                                         y: quadrilateral.bottomLeft.y * baseImage.size.height))
              } else {
                path.move(to: CGPoint(x: wordQuadrilaterals[partIndex - 1].topRight.x * baseImage.size.height,
                                      y: wordQuadrilaterals[partIndex - 1].topRight.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: wordQuadrilaterals[partIndex + 1].topLeft.x * baseImage.size.height,
                                         y: wordQuadrilaterals[partIndex + 1].topLeft.y * baseImage.size.height))
                path.move(to: CGPoint(x: wordQuadrilaterals[partIndex - 1].bottomLeft.x * baseImage.size.height,
                                         y: wordQuadrilaterals[partIndex - 1].bottomLeft.y * baseImage.size.height))
                path.addLine(to: CGPoint(x: wordQuadrilaterals[partIndex + 1].bottomRight.x * baseImage.size.height,
                                         y: wordQuadrilaterals[partIndex + 1].bottomRight.y * baseImage.size.height))
              }
              
              strokeColor.setStroke()
              path.stroke()
            }
          }
        }
      }
    }
  }
  return renderedImage
}

extension PictureShowPage {
  func definitionForWord(at index: Int) -> [String] {
    guard let word = texts?[index],
          let wordData = definitions![word.texts] else {
      return []
    }
    
    if let posDefinitions = wordData[word.pos], !posDefinitions.isEmpty {
      return posDefinitions
    }
    
    return wordData.values.flatMap { $0 }
  }
}
