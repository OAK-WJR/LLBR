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
  let format = ResultsFormat()
  let textProcessor = TextSplitter()
  
  // Dispatcher: calls the matching processing method for the input type
  func classifyAndProcess(content: Any) -> PageContent? {
    // Call a different processing method depending on the content type
    if let inputImage = content as? UIImage {
      let (words, rects) = ocr.processImage(inputImage: inputImage)
      let (formatedWords, formatedQuadrilaterals) = format.processImage(image: inputImage, allTexts: words, allRects: rects)!
      
      let finalWords = formatedWords.flatMap{$0}
      let finalPositions = formatedQuadrilaterals.flatMap{$0}
      let pointer = textProcessor.process(words: formatedWords)
      
      return PageContent(texts: finalWords, positions: finalPositions, pointer: pointer!)
      
    } else if let inputAudio = content as? URL {
      let (words, timeRanges) = ocr.processAudio(inputAudio: inputAudio)
      let (formatedWords, formatedTimeRanges) = format.processAudio(audio: inputAudio, allTexts: words, allTimeRanges: timeRanges)!
      let pointer = textProcessor.process(words: formatedWords)
      return PageContent(texts: formatedWords.flatMap{$0}, positions: formatedTimeRanges.flatMap{$0}, pointer: pointer!)
      
    } else if let inputText = content as? String {
      let words = ocr.processText(inputText: inputText)
      let formatedWords = format.processText(allTexts: words)!
      let pointer = textProcessor.process(words: formatedWords)
      return PageContent(texts: formatedWords.flatMap{$0}, positions: nil, pointer: pointer!)
      
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
