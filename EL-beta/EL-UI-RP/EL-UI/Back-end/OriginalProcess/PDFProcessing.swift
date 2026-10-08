//
//  PDFProcessing.swift
//  EL-UI
//
//  Created by WJR on 11/14/24.
//

import SwiftUI
import PDFKit

class PDFProcessing {
  func addHighlightedQuadrilateralsToPDF(pdfDocument: PDFDocument, pageInformation: RPInfoContent, pageIndex: Int) {
    guard let pdfPage = pdfDocument.page(at: pageIndex) else { return }
    
    let fillColor = UIColor.yellow.withAlphaComponent(0.3)
    let pageHeight = pdfPage.bounds(for: .mediaBox).height
    let pageWidth = pdfPage.bounds(for: .mediaBox).width
    
    if let positions = pageInformation.positions, !positions.isEmpty {
      let unknownWordsIndex = pageInformation.unknownWordsIndex ?? []
      
      for (index, quadrilaterals) in positions.enumerated() where unknownWordsIndex.contains(index) {
        // Create a combined path that merges the paths of all `Quadrilateral`s into one
        let combinedPath = UIBezierPath()
        
        for quadrilateral in quadrilaterals {
          // Build the quadrilateral path and add it to `combinedPath`
          let path = UIBezierPath()
          path.move(to: CGPoint(x: quadrilateral.topLeft.x * pageWidth, y: pageHeight - quadrilateral.topLeft.y * pageHeight))
          path.addLine(to: CGPoint(x: quadrilateral.topRight.x * pageWidth, y: pageHeight - quadrilateral.topRight.y * pageHeight))
          path.addLine(to: CGPoint(x: quadrilateral.bottomRight.x * pageWidth, y: pageHeight - quadrilateral.bottomRight.y * pageHeight))
          path.addLine(to: CGPoint(x: quadrilateral.bottomLeft.x * pageWidth, y: pageHeight - quadrilateral.bottomLeft.y * pageHeight))
          path.close()
          
          combinedPath.append(path)
        }
        
        // Create a single `PDFAnnotation` that represents the whole `[Quadrilateral]` list
        let annotationBounds = combinedPath.bounds
        let annotation = PDFAnnotation(bounds: annotationBounds, forType: .highlight, withProperties: nil)
        annotation.color = fillColor
        
        // Use `addAdditionalPath` to add the combined path so it becomes a single annotation
        annotation.add(combinedPath)
        
        // Add the annotation to the PDF page
        pdfPage.addAnnotation(annotation)
      }
    }
  }
  
  func updateAnnotationForQuadrilateral(pdfDocument: PDFDocument, pageIndex: Int, quadrilaterals: [Quadrilateral], shouldAdd: Bool) {
    guard let pdfPage = pdfDocument.page(at: pageIndex) else { return }
    
    let fillColor = UIColor.yellow.withAlphaComponent(0.3)
    let pageHeight = pdfPage.bounds(for: .mediaBox).height
    let pageWidth = pdfPage.bounds(for: .mediaBox).width
    
    let combinedPath = UIBezierPath()
    
    for quadrilateral in quadrilaterals {
      let path = UIBezierPath()
      path.move(to: CGPoint(x: quadrilateral.topLeft.x * pageWidth, y: pageHeight - quadrilateral.topLeft.y * pageHeight))
      path.addLine(to: CGPoint(x: quadrilateral.topRight.x * pageWidth, y: pageHeight - quadrilateral.topRight.y * pageHeight))
      path.addLine(to: CGPoint(x: quadrilateral.bottomRight.x * pageWidth, y: pageHeight - quadrilateral.bottomRight.y * pageHeight))
      path.addLine(to: CGPoint(x: quadrilateral.bottomLeft.x * pageWidth, y: pageHeight - quadrilateral.bottomLeft.y * pageHeight))
      path.close()
      
      combinedPath.append(path)
    }
    
    if shouldAdd {
      let annotation = PDFAnnotation(bounds: combinedPath.bounds, forType: .highlight, withProperties: nil)
      annotation.color = fillColor
      annotation.add(combinedPath)
      pdfPage.addAnnotation(annotation)
    } else {
      for annotation in pdfPage.annotations {
        if annotation.bounds == combinedPath.bounds && annotation.color == fillColor {
          pdfPage.removeAnnotation(annotation)
          break
        }
      }
    }
  }
}
