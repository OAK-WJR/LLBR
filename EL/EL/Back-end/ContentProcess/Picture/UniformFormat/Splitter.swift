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
  func process(words: [String?], postions: [Any?]) -> Pointer? {
    // Find the phrase boundaries
    let phrasePointer = self.splitIntoPhrases(wordTexts: words, wordPostions: postions)
    let sentencePointer = self.splitIntoSentences(phraseTexts: words, phrasePostions: postions)
    
    return Pointer(phrasePointer: phrasePointer, sentencePointer: sentencePointer)
  }
  
  private func splitIntoPhrases(wordTexts: [String?], wordPostions: [Any?]) -> [Range<Int>?] {
    // Add code here to combine words into phrases
    //Ex: ["Can","you","pick","up","my","bagpack?","Yes,","I","can."]
    //  ->[2..<4]
    return [nil]
  }
  
  private func splitIntoSentences(phraseTexts: [String?], phrasePostions: [Any?]) -> [Range<Int>?] {
    // Add code here to create a pointer to each sentence range
    //Ex: ["Can","you","pick", "up","my","bagpack?","Yes,","I","will."]
    //  ->[0..<5,5..<8]
    return [nil]
  }
}
