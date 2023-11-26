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
    
    func zipImage(image: UIImage) -> UIImage? {
      let resizedImage = resizeImage(image: image, maxDimension: 1080)
      let compressedImageData = compressImage(image: resizedImage)
      
      print("Compressed image size: \(String(describing: compressedImageData)) bytes")
      print("Original image size: \(image.pngData()?.count ?? 0) bytes")
      
      return UIImage(data: compressedImageData!) ?? nil
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

    
    private func resizeImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
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
    
    private func compressImage(image: UIImage) -> Data? {
      return image.jpegData(compressionQuality: 0.7)
    }
    
  }
}
