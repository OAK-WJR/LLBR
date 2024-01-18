//
//  ReadingView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI
import Vision

struct ReadingView: View {
  let screen = UIScreen.main.bounds.size
  
  var bookName: String
  var pageIndex: Int
  
  var image: UIImage
  @Binding var pictureShowPage: PictureShowPage

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
  
  var body: some View {
    VStack(spacing: 0) {
      Button("Show Words") {
        self.showSheet = true
      }
      
      Image(uiImage: showingImage ?? image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .onAppear {
          scaleFactor = screen.width / (showingImage ?? image).size.width
          pictureRealSize = CGSize(width: (showingImage ?? image).size.width * scaleFactor,
                                   height: (showingImage ?? image).size.height * scaleFactor)
          zoom = 1.0
          previousZoom = 1.0
          offset = CGSize.zero
          previousOffset = CGSize.zero
        }
        .offset(offset)
        .scaleEffect(zoom)
        .overlay(
          GeometryReader { geometry in
            
            Color.white.opacity(0.0000001)
              .onTapGesture(count: 2) { value in
                let pictureFrame = geometry.frame(in: .local)
                
                let tapPosition = CGPoint(x: (pictureFrame.midX * zoom - pictureFrame.midX + value.x) / zoom - offset.width,
                                          y: (pictureFrame.midY * zoom - pictureFrame.midY + value.y) / zoom - offset.height)
                
                if let positions = pictureShowPage.positions {
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
                    if pictureShowPage.unknowWordsIndex!.contains(closestIndex) {
                      pictureShowPage.unknowWordsIndex!.remove(at: pictureShowPage.unknowWordsIndex!.firstIndex(of: closestIndex)!)
                      
                      DispatchQueue.global(qos: .userInitiated).async {
                        let word = Lemmatization().morphy(words: [pictureShowPage.texts![closestIndex]])
                        LearedWordsDatabase().add(word)
                      }
                    }
                    
                    pictureShowPage.unknowWordsIndex!.sort()
                    showingImage = drawQuadrilateralsOnImage(pageInformation: pictureShowPage, baseImage: image)
                  }
                }
              }
              .onTapGesture(count: 1) { value in
                let pictureFrame = geometry.frame(in: .local)
                
                let tapPosition = CGPoint(x: (pictureFrame.midX * zoom - pictureFrame.midX + value.x) / zoom - offset.width,
                                          y: (pictureFrame.midY * zoom - pictureFrame.midY + value.y) / zoom - offset.height)
                
                if let positions = pictureShowPage.positions {
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
                    if !pictureShowPage.unknowWordsIndex!.contains(closestIndex) {
                      pictureShowPage.unknowWordsIndex!.append(closestIndex)
                      
                      DispatchQueue.global(qos: .userInitiated).async {
                        let word = Lemmatization().morphy(words: [pictureShowPage.texts![closestIndex]])
                        LearedWordsDatabase().remove([word[0]])
                      }
                    }
                    pictureShowPage.unknowWordsIndex!.sort()
                    showingImage = drawQuadrilateralsOnImage(pageInformation: pictureShowPage, baseImage: image)
                    
                    selectedTabIndex = closestIndex
                  }
                }
              }
              .simultaneousGesture(
                MagnificationGesture(minimumScaleDelta: 0)
                  .onChanged { value in
                    let delta = value / previousZoom
                    previousZoom = value
                    if zoom * delta >= 1.0 {
                      zoom *= delta
                    } else {
                      zoom = 1.0
                    }
                  }
                  .onEnded { value in
                    previousZoom = 1.0
                    withAnimation {
                      offset = pictrueSides(pRS: pictureRealSize,
                                            zoom: zoom,
                                            newOffset: offset)
                    }
                  }
                  .simultaneously(with: DragGesture(minimumDistance: 0)
                    .onChanged { value in
                      let translation = CGSize(
                        width: value.translation.width / zoom,
                        height: value.translation.height / zoom
                      )
                      
                      offset = pictrueSides(pRS: pictureRealSize,
                                            zoom: zoom,
                                            newOffset: CGSize(width: previousOffset.width + translation.width,
                                                              height: previousOffset.height + translation.height))
                    }
                    .onEnded { value in
                      previousOffset = offset
                    }
                  )
              )
          }
            .border(.red)
        )
        .mask {
          Rectangle()
        }
        .frame(width: pictureRealSize.width)
        .ignoresSafeArea(.all)
      
      Spacer(minLength: 0)
      
      TabView(selection: $selectedTabIndex) {
        ForEach(pictureShowPage.unknowWordsIndex ?? [], id: \.self) { index in
          WordCardView(pictureShowPage: $pictureShowPage, index: index, bookName: bookName, pageIndex: pageIndex)
            .tag(index)
        }
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      .frame(height: 90)
    }
    .onAppear {
      showingImage = drawQuadrilateralsOnImage(pageInformation: pictureShowPage, baseImage: image)
    }
    .sheet(isPresented: $showSheet) {
      WordsSheetView(bookName: bookName)
    }
  }
}

struct WordCardView: View {
  @Binding var pictureShowPage: PictureShowPage
  var index: Int
  
  var bookName: String
  var pageIndex: Int
  
  var body: some View {
    HStack(alignment: .top) {
      if let word = pictureShowPage.texts?[index],
         let learningWordsIndex = pictureShowPage.learningWordsIndex {
        
        Text(word.texts.capitalized)
          .font(.system(size: 15))
          .fontWeight(.bold)
          .foregroundColor(Color.blue)
        
        Divider()
        
        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: 5) {
            ForEach(pictureShowPage.definitionForWord(at: index), id: \.self) { definition in
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
            pictureShowPage.learningWordsIndex?.remove(at: (pictureShowPage.learningWordsIndex?.firstIndex(of: index))!)
            DispatchQueue.global(qos: .userInitiated).async {
              UnknowWordsDatabase().remove(words: [word.texts])
            }
          } else {
            pictureShowPage.learningWordsIndex?.append(index)
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

extension PictureShowPage {
  func definitionForWord(at index: Int) -> [String] {
    guard let word = texts?[index],
          let wordData = definitions![word.texts] else {
      return []
    }
    
    if let posDefinitions = wordData.definitions[word.pos], !posDefinitions.isEmpty {
      return posDefinitions
    }
    
    return wordData.definitions.values.flatMap { $0 }
  }
}

struct WordsSheetView: View {
  var bookName: String
  @State private var words: [String] = []
  
  var body: some View {
    if !words.isEmpty {
      List(words, id: \.self) { word in
        Text(word)
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

func drawQuadrilateralsOnImage(pageInformation: PictureShowPage, baseImage: UIImage) -> UIImage {
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
