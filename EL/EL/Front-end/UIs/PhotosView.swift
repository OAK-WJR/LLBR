//
//  PhotosView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

struct PhotosView: View {
  @Binding var bookName: String
  @Binding var pageIndex: Int
  @Binding var ids: [Int]
  @State var pictures = [UIImage]()
  @State var imagesPerLine: Int = 4
  
  @State var image = UIImage()
  @State var result = PictureShowPage()
  
  @State var showReadingView: Bool = false
  var body: some View {
    if pictures.count != 0 {
      if (result.texts ?? [Word]()).isEmpty {
        ScrollView {
          LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: -60), count: imagesPerLine), spacing: 2) {
            ForEach(0..<pictures.count, id: \.self) { idx in
              Button(action: {
                DispatchQueue.global(qos: .userInitiated).async {
                  pageIndex = ids[idx] - 1
                  print(pageIndex)
                  
                  let getImage_StartTime = Date()
                  let bookPageContent = BooksDatabase().getOriginal(at: [ids[pageIndex]], from: bookName)[0]
                  let getImage_Time = Date().timeIntervalSince(getImage_StartTime)
                  
                  if let image = bookPageContent.original {
                    
                    let getContent_StartTime = Date()
                    //get book content
                    var pageContent = BooksDatabase().getContent(at: [ids[pageIndex]], from: bookName)[0]
                      //if no content, then recognize the image
                    if pageContent == nil {
                      pageContent = UniformFormat().classifyAndProcess(content: image)!
                      print("Words: \(pageContent!.texts.count)")
                      print("Positions: \(pageContent!.positions!.count)")
                      BooksDatabase().addContent(at: ids[pageIndex], content: pageContent!, to: bookName)
                    }
                    let getContent_Time = Date().timeIntervalSince(getContent_StartTime)
                    
                    //get words, learnedWords, definitions)
                    let (formatedWords, learnedFilteredWordsIndex, definitions) = TextFilter().textFilter(from: pageContent!)
                    
                    //get learningWordsIndex
                    let getLearningWordsIndex_StartTime = Date()
                    let learningWordsIndex = UnkowWordsFilter().filter(originalWords: formatedWords, bookIndex: bookName, pageIndex: pageIndex)
                    let getLearningWordsIndex_Time = Date().timeIntervalSince(getLearningWordsIndex_StartTime)
                    
                    var finalLearnedFilteredWordsIndex = [Int]()

                    var unknowWords = [String]()
                    for index in learnedFilteredWordsIndex {
                      let word = formatedWords[index].texts
                      if definitions[word] != nil && !unknowWords.contains(word) {
                        finalLearnedFilteredWordsIndex.append(index)
                        unknowWords.append(word)
                      }
                    }
                    finalLearnedFilteredWordsIndex = Set(finalLearnedFilteredWordsIndex + learningWordsIndex).sorted()
                    
                    print("getImage_Time: \(getImage_Time)")
                    print("getContent_Time: \(getContent_Time)")
                    print("getLearningWordsIndex_Time: \(getLearningWordsIndex_Time)")
                    
                    DispatchQueue.main.async {
                      self.image = image
                      result = PictureShowPage(texts: formatedWords as [Word],
                                               positions: pageContent?.positions as? [[Quadrilateral]],
                                               unknowWordsIndex: finalLearnedFilteredWordsIndex as [Int],
                                               learningWordsIndex: learningWordsIndex as [Int],
                                               definitions: definitions as [String: (word: String, definitions: [POSType: [String]])])
                    }
                  }
                }
                showReadingView = true
              }) {
                Image(uiImage: pictures[idx])
                  .resizable()
                  .scaledToFill()
                  .frame(maxWidth: .infinity)
                  .clipped()
              }
            }
          }
          .padding(2)
        }
      } else {
        ReadingView(bookName: bookName, pageIndex: pageIndex, image: image, pictureShowPage: $result)
      }
    } else {
      LoadingView()
        .onAppear {
          DispatchQueue.global(qos: .userInitiated).async {
            ids = BooksDatabase().getAllIds(from: bookName)
            
            var thumbnailPictures = [UIImage]()
            let batchSize = 10
            let totalBatches = (ids.count + batchSize - 1) / batchSize
            
            for batchIndex in 0..<totalBatches {
              let batchStartIndex = batchIndex * batchSize
              let batchEndIndex = min(batchStartIndex + batchSize, ids.count)
              let batchIds = Array(ids[batchStartIndex..<batchEndIndex])
              
              let originals = BooksDatabase().getOriginal(at: batchIds, from: bookName)
                .compactMap { $0.original }
              
              if let thumbnails = OriginalProcessing.Photo().createThumbnail(images: originals,
                                                                             targetSize: CGSize(width: 100, height: 100)) {
                thumbnailPictures.append(contentsOf: thumbnails)
              }
            }
            
            DispatchQueue.main.async {
              pictures = thumbnailPictures
            }
          }
        }
    }
  }
}
