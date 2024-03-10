//
//  Attributes.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import Foundation
import UIKit

// MARK: - Basic Definitions

struct Quadrilateral: Codable {
  var topLeft: CGPoint
  var topRight: CGPoint
  var bottomRight: CGPoint
  var bottomLeft: CGPoint
}

enum POSType: String, Codable {
  case noun
  case verb
  case adjective
  case adverb
  case pronoun
  case preposition
  case conjunction
  case interjection
  case determiner
  case other
  
  var stringValue: String {
    switch self {
    case .noun: return "noun"
    case .verb: return "verb"
    case .adjective: return "adjective"
    case .adverb: return "adverb"
    case .pronoun: return "pronoun"
    case .preposition: return "preposition"
    case .conjunction: return "conjunction"
    case .interjection: return "interjection"
    case .determiner: return "determiner"
    case .other: return "other"
    }
  }
}

enum Direction {
  case up
  case down
  case left
  case right
  case none
}

struct InterfaceData {
  static let photoScale: CGFloat = 16/9
  
  static let sidebarScaleH: CGFloat = 10/100
  static let sidebarScaleL: CGFloat = 80/100
}

// MARK: - Book Structures

struct Pointer {
  var phrasePointer: [Range<Int>?]
  var sentencePointer: [Range<Int>?]
}

//Content info for one page
struct PageContent {
  var texts: [String]
  var positions: [Any]?
  var pointer: Pointer
}

struct Page {
  var ID: Int?
  var date: Date?
  var type: String?
  var original: Any?
  var crop: [[CGFloat]]?
  var content: PageContent?
  
}

struct PictureShowPage: Codable {
  var texts: [Word]?
  var positions: [[Quadrilateral]]?
  var unknowWordsIndex: [Int]?
  var learningWordsIndex: [Int]?
  var definitions: [String:[POSType:[String]]]?
}

struct BookInfo {
  var name: String
  var coverImage: UIImage?
  var addTime: Date
  var finalOpenTime: Date
  var pageNumber: Int
}

// MARK: - LearedWords Structure

struct Word: Codable {
  var texts: String
  var pos: POSType
}
