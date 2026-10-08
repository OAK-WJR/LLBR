//
//  ContentLoaders.swift
//  EL-UI
//
//  Created by WJR on 4/8/24.
//

import SwiftUI
import PDFKit

struct PDFContent {
  var pdf: PDFDocument
  var contents: [PDFPageContent]
}
struct PDFPageContent {
  var id: Int
  var imageType: ShowingImageType
  var textContent: RPInfoContent?
}

class PDFGenerator {
  // Singleton instance
  static let shared = PDFGenerator()
  
  var pdfContent = PDFContent(pdf: PDFDocument(), contents: [])
  var currentPageIndex = 0
  var bookName: String = ""
  var chapter: Int = 0 // Add the chapter property
  
  private let maxTaskCount = 3
  
  private let operationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    return queue
  }()
  
  var processingPages = Set<Int>()
  let processingQueue = DispatchQueue(label: "com.pdfgenerator.processingQueue")
  
  let booksDB = BooksDatabase()
  let dictionaryDB = DictionaryDatabase()
  let unknowWordsDB = UnknowWordsDatabase()
  let learnedWordsDB = LearedWordsDatabase()
  
  private init() {}
  
  func createInitialPDF(bookName: String, chapter: Int) -> PDFContent {
    self.bookName = bookName // Initialize bookName
    self.chapter = chapter   // Initialize chapter
    let ids = booksDB.getAllIds(from: bookName, chapterId: chapter)
    addPages(pdfContent: pdfContent, ids: ids, bookName: bookName)
    return pdfContent
  }
  
  /*
  private func addPages(pdfContent: PDFContent, ids: [Int], bookName: String) {
    for (index, id) in ids.enumerated() {
      // Check whether the page already exists
      if pdfContent.contents.contains(where: { $0.id == id }) {
        continue // Already exists, skip adding
      }
      
      if let image = booksDB.getOriginal(at: [id], from: bookName).first?.original {
        if let pdfPage = PDFPage(image: image) {
          let insertIndex = index + currentPageIndex
          pdfContent.pdf.insert(pdfPage, at: insertIndex)
          let pageContent = PDFPageContent(id: id, imageType: .clear, textContent: nil)
          self.pdfContent.contents.insert(pageContent, at: insertIndex)
        }
      }
    }
    currentPageIndex += ids.count
  }
   */
  private func addPages(pdfContent: PDFContent, ids: [Int], bookName: String) {
    for (index, id) in ids.enumerated() {
      // Check if page already exists
      if pdfContent.contents.contains(where: { $0.id == id }) {
        continue
      }
      
      if let image = booksDB.getOriginal(at: [id], from: bookName).first?.original {
        if let pdfPage = PDFPage(image: image) {
          let insertIndex = min(index + currentPageIndex, pdfContent.pdf.pageCount)
          pdfContent.pdf.insert(pdfPage, at: insertIndex)
          let pageContent = PDFPageContent(id: id, imageType: .clear, textContent: nil)
          
          // Safely insert into contents array
          if insertIndex <= self.pdfContent.contents.count {
            self.pdfContent.contents.insert(pageContent, at: insertIndex)
          } else {
            self.pdfContent.contents.append(pageContent)
          }
        }
      }
    }
    currentPageIndex += ids.count
  }
  
  // Modified prioritizePageProcessing method
  func prioritizePageProcessing(pdfContent: PDFContent, pageIndex: Int, chapterNow: Int) {
    let ids = booksDB.getAllIds(from: bookName, chapterId: chapterNow)
    let totalPageCount = ids.count
    
    // Set a range of 10 pages before and after
    let rangeToKeep = max(0, pageIndex - 10)...min(totalPageCount - 1, pageIndex + 10)
    
    // Clear annotations that are out of range
    for (index, pageContent) in self.pdfContent.contents.enumerated() {
      if !rangeToKeep.contains(index) {
        // Delete annotations that are out of range
        self.pdfContent.contents[index].imageType = .clear
        self.pdfContent.contents[index].textContent = nil
        if let pdfPage = pdfContent.pdf.page(at: index) {
          pdfPage.annotations.forEach { pdfPage.removeAnnotation($0) }
        }
      }
    }
    // Define the content loading range (3 pages before and after)
    let contentRange = max(0, pageIndex - 5)...min(totalPageCount - 1, pageIndex + 5)
    
    for index in contentRange {
      let pageContent = self.pdfContent.contents[index]
      
      // Check whether the page content was already processed (avoid loading twice)
      guard pageContent.imageType != .mark else { continue }
      
      // Check whether it is already in the processing queue
      self.processingQueue.sync {
        guard !PDFGenerator.shared.processingPages.contains(pageContent.id) else { return }
      }
      
      // Load the page content
      print("Loading content for page \(pageContent.id)")
      if let pdfPage = pdfContent.pdf.page(at: index) {
        var baseImage: UIImage? = pdfPage.thumbnail(of: pdfPage.bounds(for: .mediaBox).size, for: .mediaBox)
        self.loadInformation(for: pageContent.id, atPageIndex: index, baseImage: baseImage!, priority: .veryHigh) {
          baseImage = nil
        }
      }
    }
  }
  
  //  func loadRemainingPages(bookName: String, chapter: Int, startingIndex: Int) {
  //    let ids = BooksDatabase.shared.getAllIds(from: bookName, chapterId: chapter)
  //    let remainingPageIds = Array(ids.dropFirst(startingIndex))
  //
  //    // Fetch the original images of all remaining pages in one batch
  //    DispatchQueue.global(qos: .background).async {
  //      let originalImages = BooksDatabase.shared.getOriginal(at: remainingPageIds, from: bookName).compactMap { $0.original }
  //
  //      // Insert each image into a PDF page in turn
  //      DispatchQueue.main.async {
  //        for (index, image) in originalImages.enumerated() {
  //          let pageId = remainingPageIds[index]
  //          let insertIndex = self.currentPageIndex + index
  //
  //          // If a PDFPage was created, insert it into the PDF
  //          if let pdfPage = PDFPage(image: image) {
  //            self.pdfContent.pdf.insert(pdfPage, at: insertIndex)
  //            let pageContent = PDFPageContent(id: pageId, imageType: .clear, textContent: nil)
  //            self.pdfContent.contents.insert(pageContent, at: insertIndex)
  //          }
  //        }
  //
  //        // Update the current page index and tell the UI to refresh
  //        self.currentPageIndex += originalImages.count
  //        NotificationCenter.default.post(name: .didAddNewPDFPage, object: nil)
  //      }
  //    }
  //  }
  
  // Modified loadInformation method
  func loadInformation(for id: Int, atPageIndex pageIndex: Int, baseImage: UIImage, priority: Operation.QueuePriority = .normal, completion: @escaping () -> Void) {
    processingQueue.sync {
      if processingPages.contains(id) {
        // Already being processed, return right away
        return
      } else {
        processingPages.insert(id)
      }
    }
    
    // Check the number of tasks; if over the limit, cancel the oldest task
    if operationQueue.operationCount >= maxTaskCount {
      if let firstOperation = operationQueue.operations.first {
        firstOperation.cancel()
      }
    }
    
    var operation: BlockOperation?
    
    operation = BlockOperation { [weak self] in
      guard let self = self else { return }
      
      Task { [weak self, weak operation] in
        guard let self = self else { return }
        
        // Check whether the task was cancelled
        if operation?.isCancelled == true {
          self.processingQueue.sync {
            self.processingPages.remove(id)
          }
          return
        }
        
        // Get or process the page content
        var pageContent = booksDB.getContent(at: [id], from: self.bookName).first!
        if pageContent == nil {
          pageContent = UniformFormat().classifyAndProcess(content: baseImage)
          if let content = pageContent {
            booksDB.addContent(at: id, content: content, to: self.bookName)
          }
        }
        guard let validPageContent = pageContent else {
          DispatchQueue.main.async {
            completion()
          }
          return
        }
        
        // Get the words, unknown word indexes and definitions
        let (formatedWords, unknowWordsIndex, definitions) = await TextFilter().textFilter(from: validPageContent)
        
        // Build the index dictionary
        var indexed: [String: [Int]] = [:]
        for (index, word) in formatedWords.enumerated() {
          indexed[word.texts.lowercased(), default: []].append(index)
        }
        
        // Process unknown words
        var finalUnknowWordsIndex = [Int]()
        var unknowWords = [String]()
        for index in unknowWordsIndex {
          let word = formatedWords[index].texts
          if definitions[word.lowercased()]?.definitions != nil && !unknowWords.contains(word.lowercased()) {
            finalUnknowWordsIndex.append(index)
            unknowWords.append(word.lowercased())
          }
        }
        
        // Add new words to the learning word list
        var newLearningWords: [String] = []
        for index in finalUnknowWordsIndex {
          let word = formatedWords[index].texts
          if word.first!.isLowercase {
            newLearningWords.append(word)
          }
        }
        
        unknowWordsDB.add(words: newLearningWords, bookIndex: self.bookName, pageIndex: id)
        
        // Get the learning word indexes
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
        
        var sentences: [Range<Int>: String] = [:]
        for range in validPageContent.pointer.sentencePointer {
          let sentenceWords = validPageContent.texts[range!].joined(separator: " ")
          sentences[range!] = sentenceWords
        }
        
        let textContent = RPInfoContent(
          texts: formatedWords,
          positions: validPageContent.positions as? [[Quadrilateral]],
          indexed: indexed,
          sentences: sentences,
          unknownWordsIndex: finalLearnedFilteredWordsIndex,
          learningWordsIndex: learningWordsIndex,
          definitions: definitions
        )
        
        // Call this method directly in `loadInformation` to add annotations
        DispatchQueue.main.async {
          // Call the annotation function instead of creating a new PDFPage
          PDFProcessing().addHighlightedQuadrilateralsToPDF(pdfDocument: self.pdfContent.pdf, pageInformation: textContent, pageIndex: pageIndex)
          self.pdfContent.contents[pageIndex].imageType = .mark
          self.pdfContent.contents[pageIndex].textContent = textContent
          NotificationCenter.default.post(name: .didAddNewPDFPage, object: nil)
          completion()
        }
        
        // Remove from the in-progress set once the work is done
        self.processingQueue.sync {
          self.processingPages.remove(id)
        }
      }
    }
    
    operation?.queuePriority = priority
    if let op = operation {
      operationQueue.addOperation(op)
    }
  }
}

/*
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
    ids = BooksDatabase.shared.getAllIds(from: bookName, chapterId: 0)
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
    let newImages: [UIImage?] = BooksDatabase.shared.getOriginal(at: loadImagesIds, from: bookName).map{$0.original}
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
    let images: [UIImage?] = BooksDatabase.shared.getOriginal(at: loadImagesIds, from: bookName).map{$0.original}
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
            var pageContent = BooksDatabase.shared.getContent(at: [id], from: self.bookName)[0]
            //if no content, then recognize the image
            if pageContent == nil {
              pageContent = UniformFormat().classifyAndProcess(content: image)!
              BooksDatabase.shared.addContent(at: id, content: pageContent!, to: self.bookName)
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
*/
