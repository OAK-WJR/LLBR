//
//  PageListView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

struct PageListView: View {
  @Binding var mainContent: MainContentTag
  @Binding var showSideContent: Bool
  @Binding var bookName: String
  @Binding var pageIndex: Int
  @Binding var ids: [Int]
  
  @Binding var image: UIImage
  @Binding var result: PictureShowPage
  @Binding var showImage: Bool
  @Binding var showResult: Bool
  
  @State var pictures = [UIImage]()
  @State var imagesPerLine: Int = 4
  
  var body: some View {
    if !ids.isEmpty {
      List(0..<ids.count, id: \.self) { index in
        Button(action: {
          pageIndex = ids[index]
          mainContent = .reading
          
          showImage = false
          showResult = false
          
          loadContent()
          
          withAnimation(.easeInOut(duration: 0.5)) {
            showSideContent = false
          }
        }) {
          Text(String(ids[index]))
            .frame(maxWidth: .infinity)
        }
      }
    } else {
      LoadingView()
        .background(Color.gray.opacity(0.1))
    }
  }
}

extension PageListView {
  private func loadThumbnail() {
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

extension PageListView {
  private func loadContent() {
    DispatchQueue.global(qos: .userInitiated).async {
      
      let getImage_StartTime = Date()
      let bookPageContent = BooksDatabase().getOriginal(at: [pageIndex], from: bookName)[0]
      let getImage_Time = Date().timeIntervalSince(getImage_StartTime)
      
      if let image = bookPageContent.original {
        
        DispatchQueue.main.async {
          self.image = image
          showImage = true
        }
        
        let getContent_StartTime = Date()
        //get book content
        var pageContent = BooksDatabase().getContent(at: [pageIndex], from: bookName)[0]
        //if no content, then recognize the image
        if pageContent == nil {
          pageContent = UniformFormat().classifyAndProcess(content: image)!
          print("Words: \(pageContent!.texts.count)")
          print("Positions: \(pageContent!.positions!.count)")
          BooksDatabase().addContent(at: pageIndex, content: pageContent!, to: bookName)
        }
        let getContent_Time = Date().timeIntervalSince(getContent_StartTime)
        
        //get (words, learnedWords, definitions)
        let (formatedWords, learnedFilteredWordsIndex, definitions) = TextFilter().textFilter(from: pageContent!)
        
        var finalLearnedFilteredWordsIndex = [Int]()
        
        var unknowWords = [String]()
        for index in learnedFilteredWordsIndex {
          let word = formatedWords[index].texts
          if definitions[word] != nil && !unknowWords.contains(word) {
            finalLearnedFilteredWordsIndex.append(index)
            unknowWords.append(word)
          }
        }
        
        //Add the newly learned words
        var learningWords: [String] = []
        for index in finalLearnedFilteredWordsIndex {
          let word = formatedWords[index].texts
          if word.first!.isLowercase {
            learningWords.append(word)
          }
        }
        UnknowWordsDatabase().add(words: learningWords, bookIndex: bookName, pageIndex: pageIndex)
        
        //get learningWordsIndex
        let getLearningWordsIndex_StartTime = Date()
        let learningWordsIndex = UnkowWordsFilter().filter(originalWords: formatedWords, bookIndex: bookName, pageIndex: pageIndex)
        let getLearningWordsIndex_Time = Date().timeIntervalSince(getLearningWordsIndex_StartTime)
        
        finalLearnedFilteredWordsIndex = Set(finalLearnedFilteredWordsIndex + learningWordsIndex).sorted()
        
        print("getImage_Time: \(getImage_Time)")
        print("getContent_Time: \(getContent_Time)")
        print("getLearningWordsIndex_Time: \(getLearningWordsIndex_Time)")
        
        DispatchQueue.main.async {
          result = PictureShowPage(texts: formatedWords as [Word],
                                   positions: pageContent?.positions as? [[Quadrilateral]],
                                   unknowWordsIndex: finalLearnedFilteredWordsIndex as [Int],
                                   learningWordsIndex: learningWordsIndex as [Int],
                                   definitions: definitions as [String:[POSType: [String]]])
          
          do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.nonConformingFloatEncodingStrategy = .convertToString(
              positiveInfinity: "Infinity",
              negativeInfinity: "-Infinity",
              nan: "NaN"
            )
            let jsonData = try encoder.encode([result])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
              print(jsonString)
            }
          } catch {
            print("Error encoding JSON: \(error)")
          }
          
          showResult = true
        }
      }
    }
  }
}
