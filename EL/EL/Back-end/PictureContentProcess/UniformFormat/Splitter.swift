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
  func process(words: [String], postions: [Any]) -> PageContent {
    // Find the phrase boundaries
    var (phraseTexts, phrasePostions) = self.splitIntoPhrases(wordTexts: words, wordPostions: postions)
    let (sentenceTexts, sentencePostions) = self.splitIntoSentences(phraseTexts: phraseTexts, phrasePostions: phrasePostions)
    
    // Create the PageText and PagePosition structs
    let pageText = PageContentText(contents: sentenceTexts)
    let pagePosition = PageContentPosition(contents: sentencePostions)
    
    return PageContent(text: pageText, postions: pagePosition)
  }
  
  private func splitIntoPhrases(wordTexts: [String], wordPostions: [Any]) -> ([[String]], [[Any]]) {
    // Add code here to split words into phrases
  }
  
  private func splitIntoSentences(phraseTexts: [[String]], phrasePostions: [[Any]]) -> ([[[String]]], [[[Any]]]) {
    // Add code here to group phrases into sentences
  }
}
