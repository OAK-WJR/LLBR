//
//  PictureSaveProcess.swift
//  EL
//
//  Created by WJR on 11/23/23.
//

import Foundation
import UIKit

class OriginalProcessing {
  
  class Photo {
    
    static func processImage(image: UIImage) -> UIImage? {
      let resizedImage = resizeImage(image: image, maxDimension: 1080)
      let compressedImageData = compressImage(image: resizedImage)
      
      print("Compressed image size: \(String(describing: compressedImageData)) bytes")
      print("Original image size: \(image.pngData()?.count ?? 0) bytes")
      
      return UIImage(data: compressedImageData!) ?? nil
    }
    
    private static func resizeImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
      let size = image.size
      
      var ratio: CGFloat = 1.0
      if size.width > maxDimension || size.height > maxDimension {
        if size.width > size.height {
          ratio = maxDimension / size.width
        } else {
          ratio = maxDimension / size.height
        }
      }
      
      let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
      let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
      
      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      image.draw(in: rect)
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      return newImage ?? image
    }
    
    private static func compressImage(image: UIImage) -> Data? {
      return image.jpegData(compressionQuality: 0.7)
    }
    
  }
}
