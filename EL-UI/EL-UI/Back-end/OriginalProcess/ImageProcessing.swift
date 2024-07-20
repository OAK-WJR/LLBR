//
//  ImageProcessing.swift
//  EL
//
//  Created by WJR on 11/23/23.
//

import Foundation
import SwiftUI
import Vision
  
class ImageProcessing {
  
  func processImage(image: UIImage) -> UIImage? {
    let doumentImage = getDocumentImage(from: image)
    
    print("Original image size: \(image.pngData()?.count ?? 0) bytes")
    
    return doumentImage
  }
  
  private func getDocumentImage(from image: UIImage) -> UIImage? {
    guard let ciImage = CIImage(image: image) else { return nil }
    
    let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
    
    do {
      try requestHandler.perform([documentDetectionRequest])
    } catch {
      print("Document segmentation request failed: \(error)")
      return nil
    }
    
    guard let document = documentDetectionRequest.results?.first as? VNRectangleObservation,
          let ciDocumentImage = perspectiveCorrectedImage(from: ciImage, rectangleObservation: document) else {
      return nil
    }
    
    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(ciDocumentImage, from: ciDocumentImage.extent) else {
      return nil
    }
    
    return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
  }
  
  private func perspectiveCorrectedImage(from inputImage: CIImage, rectangleObservation: VNRectangleObservation ) -> CIImage? {
    let imageSize = inputImage.extent.size
    
    // Verify detected rectangle is valid.
    let boundingBox = rectangleObservation.boundingBox.scaled(to: imageSize)
    guard inputImage.extent.contains(boundingBox)
    else { print("invalid detected rectangle"); return nil}
    
    // Rectify the detected image and reduce it to inverted grayscale for applying model.
    let topLeft = rectangleObservation.topLeft.scaled(to: imageSize)
    let topRight = rectangleObservation.topRight.scaled(to: imageSize)
    let bottomLeft = rectangleObservation.bottomLeft.scaled(to: imageSize)
    let bottomRight = rectangleObservation.bottomRight.scaled(to: imageSize)
    let correctedImage = inputImage
      .cropped(to: boundingBox)
      .applyingFilter("CIPerspectiveCorrection", parameters: [
        "inputTopLeft": CIVector(cgPoint: topLeft),
        "inputTopRight": CIVector(cgPoint: topRight),
        "inputBottomLeft": CIVector(cgPoint: bottomLeft),
        "inputBottomRight": CIVector(cgPoint: bottomRight)
      ])
    return correctedImage
  }
  
  func createThumbnail(images: [UIImage], targetSize: CGSize) -> [UIImage]? {
    return images.compactMap { originalImage in
      
      UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
      defer { UIGraphicsEndImageContext() }
      
      let aspectWidth = targetSize.width / originalImage.size.width
      let aspectHeight = targetSize.height / originalImage.size.height
      let aspectRatio = min(aspectWidth, aspectHeight)
      
      originalImage.draw(in: CGRect(x: 0.0, y: 0.0, width: originalImage.size.width * aspectRatio, height: originalImage.size.height * aspectRatio))
      
      return UIGraphicsGetImageFromCurrentImageContext()
    }
  }
  
  func drawQuadrilateralsOnImage(pageInformation: RPInfoContent, baseImage: UIImage) -> UIImage {
    print(baseImage.size)
    let renderer = UIGraphicsImageRenderer(size: baseImage.size)
    let renderedImage = renderer.image { context in
      baseImage.draw(at: .zero)
      
      let strokeColor = UIColor.red
      let lineWidth: CGFloat = 1.5
      
      if let positions = pageInformation.positions,
         positions != [] {
        let unknowWordsIndex = pageInformation.unknownWordsIndex!
        for (index, wordQuadrilaterals) in positions.enumerated() {
          if unknowWordsIndex.contains(index) {
            if wordQuadrilaterals.count == 1 {
              let path = UIBezierPath()
              path.lineWidth = lineWidth
              path.move(to: CGPoint(x: wordQuadrilaterals[0].topLeft.x * baseImage.size.width,
                                    y: wordQuadrilaterals[0].topLeft.y * baseImage.size.height))
              path.addLine(to: CGPoint(x: wordQuadrilaterals[0].topRight.x * baseImage.size.width,
                                       y: wordQuadrilaterals[0].topRight.y * baseImage.size.height))
              path.addLine(to: CGPoint(x: wordQuadrilaterals[0].bottomRight.x * baseImage.size.width,
                                       y: wordQuadrilaterals[0].bottomRight.y * baseImage.size.height))
              path.addLine(to: CGPoint(x: wordQuadrilaterals[0].bottomLeft.x * baseImage.size.width,
                                       y: wordQuadrilaterals[0].bottomLeft.y * baseImage.size.height))
              path.close()
              
              strokeColor.setStroke()
              path.stroke()
            } else {
              for (partIndex, quadrilateral) in wordQuadrilaterals.enumerated() {
                let path = UIBezierPath()
                path.lineWidth = lineWidth
                if partIndex == 0 {
                  path.move(to: CGPoint(x: quadrilateral.topRight.x * baseImage.size.width,
                                        y: quadrilateral.topRight.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: quadrilateral.topLeft.x * baseImage.size.width,
                                           y: quadrilateral.topLeft.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: quadrilateral.bottomLeft.x * baseImage.size.width,
                                           y: quadrilateral.bottomLeft.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: quadrilateral.bottomRight.x * baseImage.size.width,
                                           y: quadrilateral.bottomRight.y * baseImage.size.height))
                } else if partIndex == wordQuadrilaterals.count - 1 {
                  path.move(to: CGPoint(x: quadrilateral.topLeft.x * baseImage.size.width,
                                        y: quadrilateral.topLeft.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: quadrilateral.topRight.x * baseImage.size.width,
                                           y: quadrilateral.topRight.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: quadrilateral.bottomRight.x * baseImage.size.width,
                                           y: quadrilateral.bottomRight.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: quadrilateral.bottomLeft.x * baseImage.size.width,
                                           y: quadrilateral.bottomLeft.y * baseImage.size.height))
                } else {
                  path.move(to: CGPoint(x: wordQuadrilaterals[partIndex - 1].topRight.x * baseImage.size.width,
                                        y: wordQuadrilaterals[partIndex - 1].topRight.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: wordQuadrilaterals[partIndex + 1].topLeft.x * baseImage.size.width,
                                           y: wordQuadrilaterals[partIndex + 1].topLeft.y * baseImage.size.height))
                  path.move(to: CGPoint(x: wordQuadrilaterals[partIndex - 1].bottomLeft.x * baseImage.size.width,
                                        y: wordQuadrilaterals[partIndex - 1].bottomLeft.y * baseImage.size.height))
                  path.addLine(to: CGPoint(x: wordQuadrilaterals[partIndex + 1].bottomRight.x * baseImage.size.width,
                                           y: wordQuadrilaterals[partIndex + 1].bottomRight.y * baseImage.size.height))
                }
                
                strokeColor.setStroke()
                path.stroke()
              }
            }
          }
        }
      }
    }
    return renderedImage
  }

}

extension CGPoint {
  func scaled(to size: CGSize) -> CGPoint {
    return CGPoint(x: self.x * size.width, y: self.y * size.height)
  }
}

extension CGRect {
  func scaled(to size: CGSize) -> CGRect {
    return CGRect(
      x: self.origin.x * size.width,
      y: self.origin.y * size.height,
      width: self.size.width * size.width,
      height: self.size.height * size.height
    )
  }
}

extension UIImage {
  func fixOrientation() -> UIImage? {
    if self.imageOrientation == .up {
      return self
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    self.draw(in: CGRect(origin: .zero, size: self.size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return normalizedImage
  }
}
