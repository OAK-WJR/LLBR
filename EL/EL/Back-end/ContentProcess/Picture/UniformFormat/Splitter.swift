//
//  Splitter.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import Foundation
import UIKit

// Define the TextProcessor class, which handles text and position info
class TextSplitter {
    
  // Process the text and WordBox; return PageText and PagePosition
  func process(words: [[String?]]) -> Pointer? {
    // Find the phrase boundaries
    let phrasePointer = self.splitIntoPhrases(wordTexts: words)
    let sentencePointer = self.splitIntoSentences(phraseTexts: words)
    
    return Pointer(phrasePointer: phrasePointer, sentencePointer: sentencePointer)
  }
  
  private func splitIntoPhrases(wordTexts: [[String?]]) -> [Range<Int>?] {
    // Add code here to combine words into phrases
    //Ex: ["Can","you","pick","up","my","bagpack?","Yes,","I","can."]
    //  ->[2..<4]
    return [nil]
  }
  
  private func splitIntoSentences(phraseTexts: [[String?]]) -> [Range<Int>?] {
    var sentences: [Range<Int>] = []
    var startIndex = 0
    
    for sentence in phraseTexts {
      let endIndex = startIndex + sentence.count
      sentences.append(startIndex..<endIndex)
      startIndex = endIndex
    }
    
    return sentences
  }
}
