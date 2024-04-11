//
//  ContentLoaders.swift
//  EL-UI
//
//  Created by WJR on 4/8/24.
//

import SwiftUI

class RP_ViewObserver: ObservableObject{
  @Published var shouldPerformDelayedTask: [Int: Bool] = [:]
  @Published var appearedPageIds: [Int] = []
  
  @Published var scale: CGFloat = 1.0
  @Published var previousScale: CGFloat = 1.0
  
  @Published var sizes: [Int:CGSize] = [:]
}

class RP_ContentLoader: ObservableObject {
  private let batchSize = 10 // Number of items to load per batch
  private let maxContentCount = 20 // Maximum number of content items to hold in memory
  
  @State var bookName: String = "diary"
  @Published var ids: [Int] = []
  @Published var contents: [RPContent] = []
  
  @Published var isLoading = false
  
  // Load the initial set of images
  func loadInitialContent(completion: @escaping (Bool) -> Void) {
    isLoading = true
    // Fetch all page IDs from the book
    ids = BooksDatabase().getAllIds(from: bookName)
    print(ids)
    
    // Load the initial batch of content based on maxContentCount
    let initialIndexes = Array(ids.prefix(maxContentCount))
    singleDirectionLoadViewContent(for: initialIndexes, direction: .next) {
      self.isLoading = false
    }
    
    completion(ids.isEmpty)
  }
  
  // Load more content in the given direction
  func loadMoreViewContent(direction: DataLoadDirection) {
    guard !isLoading else { return }
    isLoading = true
    
    // Determine the ID of the relevant content based on the direction of loading
    let relevantId: Int?
    switch direction {
    case .previous:
      relevantId = contents.first?.id
    case .next:
      relevantId = contents.last?.id
    }
    
    // Ensure the ID is valid and determine the new range of IDs to load
    guard let id = relevantId, let index = ids.firstIndex(of: id) else {
      isLoading = false
      return
    }
    
    let newIndexes: [Int]
    switch direction {
    case .previous:
      // Load the previous batch of content
      let start = max(0, index - batchSize)
      newIndexes = Array(ids[start..<index])
    case .next:
      // Load the next batch of content
      let end = min(ids.count, index + batchSize)
      newIndexes = Array(ids[index..<end])
    }
    
    // Load the content for the new range of IDs
    singleDirectionLoadViewContent(for: newIndexes, direction: direction) {
      // After loading new content, adjust the currently held content based on the maxContentCount
      switch direction {
      case .previous:
        if self.contents.count > self.maxContentCount {
          // If the maximum number is exceeded, remove the trailing elements
          self.contents.removeLast(self.contents.count - self.maxContentCount)
        }
      case .next:
        if self.contents.count > self.maxContentCount {
          // If the maximum number is exceeded, remove the header element
          self.contents.removeFirst(self.contents.count - self.maxContentCount)
        }
      }
      self.isLoading = false
    }
  }
  
  // Function to load view content for the specified IDs and handle the completion
  func singleDirectionLoadViewContent(for loadImagesIds: [Int], direction: DataLoadDirection, completion: @escaping () -> Void) {
    // Fetch the original images from the database for the specified IDs
    let newImages: [UIImage?] = BooksDatabase().getOriginal(at: loadImagesIds, from: bookName).map{$0.original}
    let newContents: [RPContent] = loadImagesIds.enumerated().map { (index, id) in
      RPContent(id: id, viewContent: RPViewContent(imageType: .clear, originalImage: newImages[index], showImage: newImages[index]!))
    }
    // Insert or append new images to the contents array based on the direction
    if direction == .previous {
      // Loading content to be displayed above the current content
      contents.insert(contentsOf: newContents, at: 0)
    } else {
      // Loading content to be displayed below the current content
      contents.append(contentsOf: newContents)
    }
    // Call the completion handler
    completion()
  }
  
  func doubleDirectionsLoadViewContent(for id: Int, completion: @escaping () -> Void) {
    // Calculate the range of IDs to load
    let halfRange = maxContentCount / 2
    let startIdIndex = max(0, id - halfRange)
    let endIdIndex = min(self.ids.count, id + halfRange)
    let loadImagesIds: [Int] = Array(self.ids[startIdIndex..<endIdIndex])
    // Load images for the calculated range of IDs
    let images: [UIImage?] = BooksDatabase().getOriginal(at: loadImagesIds, from: bookName).map{$0.original}
    self.contents = loadImagesIds.enumerated().map { (index, id) in
      RPContent(id: id, viewContent: RPViewContent(imageType: .clear, originalImage: images[index], showImage: images[index]!))
    }
    
    // Call the completion handler
    completion()
  }
  
  
  func loadInformation(for id: Int, completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      
      if let index = self.contents.firstIndex(where: {$0.id == id}) {
        print(self.contents.count)
        if let viewContent = self.contents[index].viewContent {
          if viewContent.imageType != .mark,
             let image = self.contents[index].viewContent?.showImage {
            
            //get book content
            var pageContent = BooksDatabase().getContent(at: [id], from: self.bookName)[0]
            //if no content, then recognize the image
            if pageContent == nil {
              pageContent = UniformFormat().classifyAndProcess(content: image)!
              BooksDatabase().addContent(at: id, content: pageContent!, to: self.bookName)
            }
            
            //get (words, learnedWords, definitions)
            let (formatedWords, unknowWordsIndex, definitions) = TextFilter().textFilter(from: pageContent!)
            
            var indexed: [String:[Int]] = [:]

            for (index, word) in formatedWords.enumerated() {
              if (indexed[word.texts.lowercased()] != nil) {
                indexed[word.texts.lowercased()]?.append(index)
              } else {
                indexed[word.texts.lowercased()] = [index]
              }
            }
            print(indexed)
            
            var finalUnknowWordsIndex = [Int]()
            
            var unknowWords = [String]()
            for index in unknowWordsIndex {
              let word = formatedWords[index].texts
              if definitions[word.lowercased()]?.definitions != nil && !unknowWords.contains(word.lowercased()) {
                finalUnknowWordsIndex.append(index)
                unknowWords.append(word.lowercased())
              }
            }
            
            //Add the new words to the learning words
            var newLearningWords: [String] = []
            for index in finalUnknowWordsIndex {
              let word = formatedWords[index].texts
              if word.first!.isLowercase {
                newLearningWords.append(word)
              }
            }
            UnknowWordsDatabase().add(words: newLearningWords, bookIndex: self.bookName, pageIndex: id)
            
            //get learningWordsIndex
            let learningWordsIndex = UnkowWordsFilter().filter(originalWords: formatedWords, bookIndex: self.bookName, pageIndex: id)
            
            var finalLearningWordsIndex = [Int]()
            
            var learningWords = [String]()
            for index in learningWordsIndex {
              let word = formatedWords[index].texts
              if !learningWords.contains(word.lowercased()) {
                finalLearningWordsIndex.append(index)
                learningWords.append(word.lowercased())
              }
            }
            
            let finalLearnedFilteredWordsIndex = Set(finalUnknowWordsIndex + finalLearningWordsIndex).sorted()
            print(finalLearnedFilteredWordsIndex)
            let textContent = RPInfoContent(texts: formatedWords as [Word],
                                        positions: pageContent?.positions as? [[Quadrilateral]],
                                        indexed: indexed,
                                        unknownWordsIndex: finalLearnedFilteredWordsIndex as [Int],
                                        learningWordsIndex: learningWordsIndex as [Int],
                                        definitions: definitions as [String:(word: String, definitions: [POSType: [String]])])
            let markedImage = ImageProcessing().drawQuadrilateralsOnImage(pageInformation: textContent, baseImage: viewContent.originalImage!)
            
            
            DispatchQueue.main.async {
              if let checkedIndex = self.contents.firstIndex(where: {$0.id == id}) {
                self.contents[checkedIndex].viewContent?.imageType = .mark
                self.contents[checkedIndex].viewContent?.showImage = markedImage
                print("\(checkedIndex): \(viewContent.originalImage!) -> \(markedImage) ")
                
                self.contents[checkedIndex].textContent = textContent
                completion()
              }
            }
          }
        }
      }
    }
  }
}
