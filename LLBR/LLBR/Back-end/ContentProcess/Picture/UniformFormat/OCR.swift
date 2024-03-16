//
//  P-OCR.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import UIKit
import Vision

class OCR {
  //MARK: - Image
  // Processes an image; returns the recognized strings and their positions
  func processImage(inputImage: UIImage) -> ([[String]], [[CGRect]]) {
    var allWords: [[String]] = []
    var allRects: [[CGRect]] = []
    
    guard let cgImage = inputImage.cgImage else { return ([], []) }
    
    
    let request = VNRecognizeTextRequest { (request, error) in
      guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
        print("Text recognition error: \(error?.localizedDescription ?? "Unknown error")")
        return
      }
      
      for observation in observations {
        guard let topCandidate = observation.topCandidates(1).first else { continue }
        
        var lineWords: [String] = []
        var lineRects: [CGRect] = []
        
        var lineBoundingBoxs: [CGRect] = []
        
        for (index, character) in topCandidate.string.enumerated() {
          let startIndex = topCandidate.string.index(topCandidate.string.startIndex, offsetBy: index)
          let endIndex = topCandidate.string.index(startIndex, offsetBy: 1)
          
          let range = startIndex..<endIndex
          
          if let wordBox = try? topCandidate.boundingBox(for: range) {
            let boundingBox = wordBox.boundingBox
            if character != " " {
              if boundingBox != lineBoundingBoxs.last {
                lineWords.append("")
                lineBoundingBoxs.append(boundingBox)
                let rect = CGRect(x: boundingBox.minX, y: 1 - boundingBox.minY - boundingBox.height, width: boundingBox.width, height: boundingBox.height)
                lineRects.append(rect)
              }
              lineWords[lineWords.count - 1] += String(character)
            }
          }
        }
        
        allWords.append(lineWords)
        allRects.append(lineRects)
      }
    }
    
    request.recognitionLevel = .accurate
    
    let handler = VNImageRequestHandler(cgImage: cgImage)
    try? handler.perform([request])
    
    return (allWords, allRects)
  }

  //MARK: - Audio
  // Processes audio; returns the recognized strings and their time ranges
  func processAudio(inputAudio: URL) -> ([[String]], [[CMTimeRange]]) {
    // Audio processing and speech recognition logic goes here
    let recognizedStrings: [[String]] = [] // placeholder for the recognized speech
    let timeRanges: [[CMTimeRange]] = [] // placeholder for the recognized speech time ranges
    return (recognizedStrings, timeRanges)
  }

  //MARK: - Text
  // Processes text; returns the processed strings
  func processText(inputText: String) -> [String] {
    // Text processing logic goes here
    let processedStrings: [String] = [] // placeholder for the processed text
    return processedStrings
  }
}
