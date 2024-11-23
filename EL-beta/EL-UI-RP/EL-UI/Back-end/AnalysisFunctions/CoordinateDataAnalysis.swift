//
//  CoordinateDataAnalysis.swift
//  EL-UI
//
//  Created by WJR on 11/14/24.
//

import SwiftUI

import CoreGraphics

class DataAnalysis {
  
  private struct SpatialIndex {
    let gridSize: CGFloat
    var index: [Int: [IndexPath]] = [:]
    
    mutating func add(quadIndex: IndexPath, boundingBox: CGRect) {
      let gridX = Int(floor(boundingBox.origin.x / gridSize))
      let gridY = Int(floor(boundingBox.origin.y / gridSize))
      let gridKey = gridX * 1_000 + gridY
      
      if index[gridKey] != nil {
        index[gridKey]?.append(quadIndex)
      } else {
        index[gridKey] = [quadIndex]
      }
    }
    
    func candidates(for point: CGPoint) -> [IndexPath] {
      let gridX = Int(floor(point.x / gridSize))
      let gridY = Int(floor(point.y / gridSize))
      let gridKey = gridX * 1_000 + gridY
      return index[gridKey] ?? []
    }
  }
  
  static func findNearestWordIndex(location: CGPoint, quadrilateralArrays: [[Quadrilateral]], gridSize: CGFloat = 10) -> IndexPath? {
    // Build the index
    var spatialIndex = SpatialIndex(gridSize: gridSize)
    for (outerIndex, quadrilaterals) in quadrilateralArrays.enumerated() {
      for (innerIndex, quad) in quadrilaterals.enumerated() {
        let boundingBox = CGRect(
          x: min(quad.topLeft.x, quad.topRight.x, quad.bottomLeft.x, quad.bottomRight.x),
          y: min(quad.topLeft.y, quad.topRight.y, quad.bottomLeft.y, quad.bottomRight.y),
          width: max(quad.topLeft.x, quad.topRight.x, quad.bottomLeft.x, quad.bottomRight.x) - min(quad.topLeft.x, quad.topRight.x, quad.bottomLeft.x, quad.bottomRight.x),
          height: max(quad.topLeft.y, quad.topRight.y, quad.bottomLeft.y, quad.bottomRight.y) - min(quad.topLeft.y, quad.topRight.y, quad.bottomLeft.y, quad.bottomRight.y)
        )
        spatialIndex.add(quadIndex: IndexPath(item: innerIndex, section: outerIndex), boundingBox: boundingBox)
      }
    }
    
    // Find the candidates
    let candidates = spatialIndex.candidates(for: location)
    
    // If there are no candidates, return nil
    guard !candidates.isEmpty else { return nil }
    
    // Go through the candidate quadrilaterals and find the nearest one
    var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude
    var nearestIndexPath: IndexPath?
    
    for candidateIndexPath in candidates {
      let quad = quadrilateralArrays[candidateIndexPath.section][candidateIndexPath.item]
      if isPointInsidePolygon(point: location, polygon: quad.corners) {
        return candidateIndexPath // If the point is already inside, return right away
      }
      
      // Compute the shortest distance from the point to the quadrilateral
      let distance = quad.minimumDistance(to: location)
      if distance < minDistance {
        minDistance = distance
        nearestIndexPath = candidateIndexPath
      }
    }
    
    return nearestIndexPath
  }
  
  private static func isPointInsidePolygon(point: CGPoint, polygon: [CGPoint]) -> Bool {
    var isInside = false
    var j = polygon.count - 1
    for i in 0..<polygon.count {
      let xi = polygon[i].x, yi = polygon[i].y
      let xj = polygon[j].x, yj = polygon[j].y
      
      if ((yi > point.y) != (yj > point.y)) &&
          (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi) {
        isInside.toggle()
      }
      j = i
    }
    return isInside
  }
}

extension Quadrilateral {
  private func distanceFrom(point: CGPoint, toLineSegment lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
    let lineLengthSquared = pow(lineEnd.x - lineStart.x, 2) + pow(lineEnd.y - lineStart.y, 2)
    guard lineLengthSquared != 0 else { return hypot(point.x - lineStart.x, point.y - lineStart.y) }
    
    let t = max(0, min(1, ((point.x - lineStart.x) * (lineEnd.x - lineStart.x) + (point.y - lineStart.y) * (lineEnd.y - lineStart.y)) / lineLengthSquared))
    let projection = CGPoint(x: lineStart.x + t * (lineEnd.x - lineStart.x), y: lineStart.y + t * (lineEnd.y - lineStart.y))
    return hypot(point.x - projection.x, point.y - projection.y)
  }
  
  func minimumDistance(to point: CGPoint) -> CGFloat {
    let distances = [
      distanceFrom(point: point, toLineSegment: topLeft, lineEnd: topRight),
      distanceFrom(point: point, toLineSegment: topRight, lineEnd: bottomRight),
      distanceFrom(point: point, toLineSegment: bottomRight, lineEnd: bottomLeft),
      distanceFrom(point: point, toLineSegment: bottomLeft, lineEnd: topLeft)
    ]
    return distances.min() ?? CGFloat.greatestFiniteMagnitude
  }
}
