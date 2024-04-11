//
//  ResultsFormat.swift
//  EL
//
//  Created by WJR on 1/3/24.
//

import Foundation
import UIKit
import AVFoundation

class ResultsFormat {
  //MARK: - Image
  func processImage(image: UIImage, allTexts: [[String]], allRects: [[CGRect]]) -> ([[String]], [[[Quadrilateral]]])? {
    var lineFunctions: [(top: (slope: Double, intercept: Double),
                         bottom: (slope: Double, intercept: Double))] = []
    
    func rectsToPositions(allTexts: [[String]], allRects: [[CGRect]]) -> ([[String]], [[Quadrilateral]]) {
      var textsWords: [[String]] = []
      var textsPositions: [[Quadrilateral]] = []
      
      for (lineIndex, lineWords) in allTexts.enumerated()  {
        let lineRects = allRects[lineIndex]
        
        if !textsWords.contains(lineWords) {
          print(lineWords)
          let midPoints = lineRects.map { rect in
            return CGPoint(x: Double(rect.midX), y: Double(rect.midY))
          }
          let midLineFunction = performLinearRegression(on: midPoints)
          
          var linePositions: [Quadrilateral] = []
          var topPoints: [CGPoint] = []
          var bottomPoints: [CGPoint] = []
          
          var topLineFunction: (slope: Double, intercept: Double)
          var bottomLineFunction: (slope: Double, intercept: Double)
          
          if midLineFunction.slope >= 0.0 {
            for i in 0 ..< lineRects.count - 1 {
              let currentRect = lineRects[i]
              let nextRect = lineRects[i + 1]
              
              let currentTopRight = CGPoint(x: currentRect.maxX, y: currentRect.minY)
              let currentBottomRight = CGPoint(x: currentRect.maxX, y: currentRect.maxY)
              let currentBottomLeft = CGPoint(x: currentRect.minX, y: currentRect.maxY)
              
              let nextTopRight = CGPoint(x: nextRect.maxX, y: nextRect.minY)
              let nextTopLeft = CGPoint(x: nextRect.minX, y: nextRect.minY)
              let nextBottomLeft = CGPoint(x: nextRect.minX, y: nextRect.maxY)
              
              topPoints.append(points_intersection(currentTopRight, currentBottomRight, nextTopLeft, nextTopRight)!)
              bottomPoints.append(points_intersection(currentBottomLeft, currentBottomRight, nextTopLeft, nextBottomLeft)!)
            }
          } else {
            for i in 0 ..< lineRects.count - 1 {
              let currentRect = lineRects[i]
              let nextRect = lineRects[i + 1]
              
              let currentTopLeft = CGPoint(x: currentRect.minX, y: currentRect.minY)
              let currentTopRight = CGPoint(x: currentRect.maxX, y: currentRect.minY)
              let currentBottomRight = CGPoint(x: currentRect.maxX, y: currentRect.maxY)
              
              let nextTopLeft = CGPoint(x: nextRect.minX, y: nextRect.minY)
              let nextBottomLeft = CGPoint(x: nextRect.minX, y: nextRect.maxY)
              let nextBottomRight = CGPoint(x: nextRect.maxX, y: nextRect.maxY)
              
              topPoints.append(points_intersection(currentTopLeft, currentTopRight, nextTopLeft, nextBottomLeft)!)
              bottomPoints.append(points_intersection(currentTopRight, currentBottomRight, nextBottomLeft, nextBottomRight)!)
            }
          }
          topLineFunction = performLinearRegression(on: topPoints)
          bottomLineFunction = performLinearRegression(on: bottomPoints)
          print(midLineFunction)
          
          if midLineFunction.slope.isInfinite {
            lineFunctions.append((top: bottomLineFunction, bottom: topLineFunction))
            
            linePositions = lineRects.map{Quadrilateral(topLeft: CGPoint(x: $0.minX, y: $0.maxY),
                                                        topRight: CGPoint(x: $0.minX, y: $0.minY),
                                                        bottomRight: CGPoint(x: $0.maxX, y: $0.minY), 
                                                        bottomLeft: CGPoint(x: $0.maxX, y: $0.maxY))}
          } else if abs(midLineFunction.slope) <= 0.02 {
            lineFunctions.append((top: topLineFunction, bottom: bottomLineFunction))
            
            linePositions = lineRects.map{Quadrilateral(topLeft: CGPoint(x: $0.minX, y: $0.minY),
                                                        topRight: CGPoint(x: $0.maxX, y: $0.minY),
                                                        bottomRight:  CGPoint(x: $0.maxX, y: $0.maxY), 
                                                        bottomLeft: CGPoint(x: $0.minX, y: $0.maxY))}
          } else {
            lineFunctions.append((top: topLineFunction, bottom: bottomLineFunction))
            
            linePositions = []
            
            for i in 0 ..< lineRects.count {
              let rect = lineRects[i]
              
              let topside = (slope: 0.0, intercept: Double(rect.minY))
              let bottomside = (slope: 0.0, intercept: Double(rect.maxY))
              let leftside = (slope: Double.infinity, intercept: Double(rect.minX))
              let rightside = (slope: Double.infinity, intercept: Double(rect.maxX))
              
              var topLeftIntersection1: CGPoint?
              var topLeftIntersection2: CGPoint?
              var bottomLeftIntersection1: CGPoint?
              var bottomLeftIntersection2: CGPoint?
              var topRightIntersection1: CGPoint?
              var topRightIntersection2: CGPoint?
              var bottomRightIntersection1: CGPoint?
              var bottomRightIntersection2: CGPoint?
              
              if midLineFunction.slope < 0 {
                topLeftIntersection1 = lineFunctions_intersection(topLineFunction, leftside)
                topLeftIntersection2 = lineFunctions_intersection(topLineFunction, bottomside)
                bottomLeftIntersection1 = lineFunctions_intersection(topLineFunction, leftside)
                bottomLeftIntersection2 = lineFunctions_intersection(topLineFunction, bottomside)
                
                topRightIntersection1 = lineFunctions_intersection(bottomLineFunction, topside)
                topRightIntersection2 = lineFunctions_intersection(bottomLineFunction, rightside)
                bottomRightIntersection1 = lineFunctions_intersection(bottomLineFunction, topside)
                bottomRightIntersection2 = lineFunctions_intersection(bottomLineFunction, rightside)
              } else {
                topLeftIntersection1 = lineFunctions_intersection(topLineFunction, topside)
                topLeftIntersection2 = lineFunctions_intersection(topLineFunction, leftside)
                bottomLeftIntersection1 = lineFunctions_intersection(bottomLineFunction, topside)
                bottomLeftIntersection2 = lineFunctions_intersection(bottomLineFunction, leftside)
                
                topRightIntersection1 = lineFunctions_intersection(topLineFunction, rightside)
                topRightIntersection2 = lineFunctions_intersection(topLineFunction, bottomside)
                bottomRightIntersection1 = lineFunctions_intersection(bottomLineFunction, rightside)
                bottomRightIntersection2 = lineFunctions_intersection(bottomLineFunction, bottomside)
              }
              
              let topLeftLineIntersection = topLeftIntersection1?.x ?? 0 > topLeftIntersection2?.x ?? 0 ? topLeftIntersection1 : topLeftIntersection2
              let bottomLeftLineIntersection = bottomLeftIntersection1?.x ?? 0 > bottomLeftIntersection2?.x ?? 0 ? bottomLeftIntersection1 : bottomLeftIntersection2
              let topRightIntersection = topRightIntersection1?.x ?? 2 < topRightIntersection2?.x ?? 2 ? topRightIntersection1 : topRightIntersection2
              let bottomRightIntersection = bottomRightIntersection1?.x ?? 2 < bottomRightIntersection2?.x ?? 2 ? bottomRightIntersection1 : bottomRightIntersection2
              
              let leftCenterPoint = CGPoint(x: (topLeftLineIntersection!.x + bottomLeftLineIntersection!.x) / 2,
                                            y: (topLeftLineIntersection!.y + bottomLeftLineIntersection!.y) / 2)
              let rightCenterPoint = CGPoint(x: (topRightIntersection!.x + bottomRightIntersection!.x) / 2,
                                             y: (topRightIntersection!.y + bottomRightIntersection!.y) / 2)
              
              let topLeftPoint = perpendicular_intersection(lineFunction: topLineFunction, center: leftCenterPoint)!
              let bottomLeftPoint = perpendicular_intersection(lineFunction: bottomLineFunction, center: leftCenterPoint)!
              let topRightPoint = perpendicular_intersection(lineFunction: topLineFunction, center: rightCenterPoint)!
              let bottomRightPoint = perpendicular_intersection(lineFunction: bottomLineFunction, center: rightCenterPoint)!
              
              linePositions.append(Quadrilateral(topLeft: topLeftPoint, topRight: topRightPoint, bottomRight: bottomRightPoint, bottomLeft: bottomLeftPoint))
            }
          }
          textsWords.append(lineWords)
          textsPositions.append(linePositions)
        }
      }
      return (textsWords, textsPositions)
    }
  
    func formatSentencesAndPositions(_ words: [[String]], _ positions: [[Quadrilateral]]) -> ([[String]], [[[Quadrilateral]]]) {
      var originalWords: [[String]] = words
      var originalPositions: [[Quadrilateral]] = positions
      let endSymbols = Set([".", "?", "!", ";", ".\"", "?\"", "!\"", ";\""])
      var formattedWords: [[String]] = []
      var formattedPositions: [[[Quadrilateral]]] = []
      
      var currentSentenceWords: [String] = []
      var currentSentencePositions: [[Quadrilateral]] = []
      
      func addNewLine() {
        if currentSentenceWords.count > 1 {
          formattedWords.append(currentSentenceWords)
          formattedPositions.append(currentSentencePositions)
          currentSentenceWords.removeAll()
          currentSentencePositions.removeAll()
        }
      }
      
      for lineIndex in 0 ..< originalWords.count {
        for wordIndex in 0 ..< originalWords[lineIndex].count {
          var word = originalWords[lineIndex][wordIndex]
          let position = originalPositions[lineIndex][wordIndex]
          
          if wordIndex == originalWords[lineIndex].count - 1 && word.hasSuffix("-") && lineIndex < originalWords.count - 1 {
            let nextLineFirstWord: String = originalWords[lineIndex + 1].first!
            let nextLineFirstPosition: Quadrilateral = originalPositions[lineIndex + 1].first!
            
            currentSentenceWords.append(String(word.dropLast() + nextLineFirstWord))
            currentSentencePositions.append([position, nextLineFirstPosition])
            
            word = nextLineFirstWord
            originalWords[lineIndex + 1].removeFirst()
            originalPositions[lineIndex + 1].removeFirst()
          } else {
            currentSentenceWords.append(word)
            currentSentencePositions.append([position])
          }
          
          
          if endSymbols.contains(where: word.hasSuffix)  {
            if word.hasSuffix(".") {
              if word.filter({ $0 == "." }).count == 1 &&
                  (word.count >= 3 && !(word[word.index(word.endIndex, offsetBy: -2)].isLowercase && word[word.index(word.endIndex, offsetBy: -3)].isUppercase) ||
                   word.count == 2 && !(word[word.index(word.endIndex, offsetBy: -2)].isUppercase)) {
                addNewLine()
              }
            } else {
              addNewLine()
            }
          }
        }
        
        if !currentSentenceWords.isEmpty {
          if lineIndex < originalWords.count - 1 {
            let currentLineFunction = lineFunctions[lineIndex]
            let nextLineFunction = lineFunctions[lineIndex + 1]
            
            var currentLineY: (top: Double, bottom: Double)
            var nextLineY: (top: Double, bottom: Double)
            
            if currentLineFunction.top.slope.isInfinite {
              currentLineY = (top: currentLineFunction.top.intercept,
                              bottom: currentLineFunction.bottom.intercept)
              nextLineY = (top: nextLineFunction.top.intercept,
                           bottom: nextLineFunction.bottom.intercept)
            } else {
              currentLineY = (top: currentLineFunction.top.intercept * 0.2 + currentLineFunction.top.intercept,
                              bottom: currentLineFunction.bottom.intercept * 0.2 + currentLineFunction.bottom.intercept)
              nextLineY = (top: nextLineFunction.top.intercept * 0.2 + nextLineFunction.top.intercept,
                           bottom: nextLineFunction.bottom.intercept * 0.2 + nextLineFunction.bottom.intercept)
            }
            let currentLineHeight = abs(currentLineY.bottom - currentLineY.top)
            let nextLineHeight = abs(nextLineY.bottom - nextLineY.top)
            let linesSpacing = abs(nextLineY.top - currentLineY.bottom)
            let averageLineHeight = (currentLineHeight + nextLineHeight) / 2
            
            let lineSpacingScale = linesSpacing / averageLineHeight
            let heightDifferenceScale = abs(currentLineHeight - nextLineHeight) / averageLineHeight
            print("lineSpacingScale: \(lineSpacingScale)")
            print("heightDifferenceScale: \(heightDifferenceScale)")
            
            if lineSpacingScale > 0.7 || heightDifferenceScale > 0.35 {
              addNewLine()
            }
          } else {
            addNewLine()
          }
        }
      }
      
      return (formattedWords, formattedPositions)
    }
    
    let (texts, positions) = rectsToPositions(allTexts: allTexts, allRects: allRects)
    //start with "sf" means "sentence form"
    let (sfTexts, sfPositions) = formatSentencesAndPositions(texts, positions)
    
    return (sfTexts, sfPositions)
  }
  
  //MARK: - Audio
  
  func processAudio(audio: URL, allTexts: [[String]], allTimeRanges: [[CMTimeRange]]) -> ([[String]], [[[CMTimeRange]]])? {
    return nil
  }
  //MARK: - Text
  
  func processText(allTexts: [String]) -> ([[String]])? {
    return nil
  }
}

public func performLinearRegression(on points: [CGPoint]) -> (slope: Double, intercept: Double) {
  let n = Double(points.count)
  let sumX = points.reduce(0) { $0 + $1.x }
  let sumY = points.reduce(0) { $0 + $1.y }
  let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
  let sumX2 = points.reduce(0) { $0 + $1.x * $1.x }

  let denominator = n * sumX2 - sumX * sumX
  guard denominator != 0 else {
      return (Double.infinity, 0)
  }

  let xMin = points.map { $0.x }.min() ?? 0
  let xMax = points.map { $0.x }.max() ?? 0
  let xRange = xMax - xMin
  
  var slope = (n * sumXY - sumX * sumY) / denominator

  if xRange < 0.001 || abs(slope) > 150 {
    return (Double.infinity, xMin)
  } else {
    slope = round(slope * 1_000_0) / 1_000_0

  }

  let intercept = (sumY - slope * sumX) / n

  return (slope, intercept)
}

                               
public func points_lineFunction(_ p1: CGPoint, _ p2: CGPoint) -> (slope: Double, intercept: Double) {
  if p1.x == p2.x {
    return (Double.infinity, Double(p1.x))
  } else {
    let slope = (p2.y - p1.y) / (p2.x - p1.x)
    let intercept = p1.y - slope * p1.x
    return (slope, intercept)
  }
}

public func lineFunctions_intersection(_ l1: (slope: Double, intercept: Double), _ l2: (slope: Double, intercept: Double)) -> CGPoint? {
  let (slope1, intercept1) = l1
  let (slope2, intercept2) = l2

  if slope1 == Double.infinity {
    let x = intercept1
    let y = slope2 * x + intercept2
    return CGPoint(x: x, y: y)
  } else if slope2 == Double.infinity {
    let x = intercept2
    let y = slope1 * x + intercept1
    return CGPoint(x: x, y: y)
  } else if slope1 == slope2 {
    return nil
  } else {
    let x = (intercept2 - intercept1) / (slope1 - slope2)
    let y = slope1 * x + intercept1
    return CGPoint(x: x, y: y)
  }
}

public func points_intersection(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> CGPoint? {
  return lineFunctions_intersection(points_lineFunction(p1, p2), points_lineFunction(p3, p4))
}

public func perpendicular_intersection(lineFunction: (slope: Double, intercept: Double), center: CGPoint) -> CGPoint? {
  if lineFunction.slope.isInfinite {
    return CGPoint(x: lineFunction.intercept, y: center.y)
  } else if lineFunction.slope == 0 {
    return CGPoint(x: center.x, y: lineFunction.intercept)
  } else {
    let perpendicularSlope: Double = -1 / lineFunction.slope
    let interceptPerpendicular: Double = center.y - perpendicularSlope * center.x
    let perpendicularLineFunction = (slope: perpendicularSlope, intercept: interceptPerpendicular)

    return lineFunctions_intersection(lineFunction, perpendicularLineFunction)
  }
}
