//
//  Attributes_FrontEnd.swift
//  EL-UI
//
//  Created by WJR on 1/24/24.
//

import Foundation
import UIKit

//MARK: - Interface control
enum ViewContent {
  case reading(Reading)
  case learning
}

enum Reading {
  case booksList
  case bookEdit
  case bookContent(BookContent)
}

enum BookContent {
  case readPage
  case addPage
}

//ReadingPageSetting
enum ReadingMode {
  case mixed
  case singe
}

enum PageFlipMode {
  case scroll
  case page
}

//MARK: - Book Structure
enum ShowingImageType {
  case clear, mark
}


struct BookInfo {
  var name: String
  var coverImage: UIImage?
  var addTime: Date
  var finalOpenTime: Date
  var pageNumber: Int
}

struct RPViewContent {
  var imageType: ShowingImageType
  let originalImage: UIImage?
  var showImage: UIImage?
}

struct RPInfoContent {
  var texts: [Word]?
  var positions: [[Quadrilateral]]?
  var indexed: [String: [Int]]?
  
  var unknownWordsIndex: [Int]?
  var learningWordsIndex: [Int]?
  
  var definitions: [String:(word: String, definitions: [POSType: [String]])]?
}

struct RPContent {
  let id: Int
  var viewContent: RPViewContent?
  var textContent: RPInfoContent?
}

//MARK: - EditRescouce
struct CroppingImage: Identifiable {
 var id: Int
 var image: UIImage?
 var cropping: Quadrilateral?
}

//MARK: - DataLoading
enum DataLoadDirection {
  case previous, next
}
