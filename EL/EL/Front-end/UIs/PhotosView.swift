//
//  PhotosView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

struct PhotosView: View {
  @Binding var bookName: String
  @Binding var index: Int
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
                  index = ids[idx] - 1
                  print(index)
                  let bookPageContent = BooksDatabase().getOriginal(at: [ids[index]], from: bookName)[0]
                  if let image = bookPageContent.original {
                    var pageContent = BooksDatabase().getContent(at: [ids[index]], from: bookName)[0]
                    if pageContent == nil {
                      pageContent = UniformFormat().classifyAndProcess(content: image)!
                      print("Words: \(pageContent!.texts.count)")
                      print("Positions: \(pageContent!.positions!.count)")
                      BooksDatabase().addContent(at: ids[index], content: pageContent!, to: bookName)
                    }
                    
                    let (formatedWords, filteredWordsIndex) = TextFilter().textFilter(from: pageContent!)
                    let definitions: [String: (word: String, definitions: [POSType: [String]])] = WordsDefinite().definition(formatedWords)
                    
                    var finalFilteredWordsIndex = [Int]()
                    for index in filteredWordsIndex {
                      if definitions[formatedWords[index].texts] != nil {
                        finalFilteredWordsIndex.append(index)
                      }
                    }
                    
                    DispatchQueue.main.async {
                      self.image = image
                      result = PictureShowPage(texts: formatedWords as [Word],
                                               positions: pageContent?.positions as? [[Quadrilateral]],
                                               unknowWordsIndex: finalFilteredWordsIndex as [Int],
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
        ReadingView(image: image, pictureShowPage: $result)
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
              
              // Create a thumbnail and append it to thumbnailPictures
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
