//
//  ContentProcessor.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import UIKit
import Foundation

class UniformFormat {
    let ocr = OCR()
    let textProcessor = TextSplitter()
    
    // Dispatcher: calls the matching processing method for the input type
    func classifyAndProcess(content: Any) -> PageContent? {
        // Call a different processing method depending on the content type
        if let inputImage = content as? UIImage {
          let (words, quadrilaterals) = ocr.processImage(inputImage: inputImage)
          let pointer = textProcessor.process(words: words, postions: quadrilaterals)
          return PageContent(texts: words, postions: quadrilaterals, pointer: pointer!)
          
        } else if let inputAudio = content as? URL {
          let (words, timeRanges) = ocr.processAudio(inputAudio: inputAudio)
          let pointer = textProcessor.process(words: words, postions: timeRanges)
          return PageContent(texts: words, postions: timeRanges, pointer: pointer!)
          
        } else if let inputText = content as? String {
          let words = ocr.processText(inputText: inputText)
          // Plain text may have no position info, so create placeholder Postions
          let none = createWordPositionsForText(words: words)
          let pointer = textProcessor.process(words: words, postions: none)
          return PageContent(texts: words, postions: none, pointer: pointer!)
          
        } else {
            // Unknown content type
            return nil
        }
    }
    // Helper function - create WordBox for plain text
    private func createWordPositionsForText(words: [String]) -> [Any] {
      let positions = words.map { _ in nil as Any? }
      return positions as [Any]
    }
}
