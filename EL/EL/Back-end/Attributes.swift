//
//  Attributes.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import Foundation
import UIKit

// MARK: - Basic Definitions

struct Quadrilateral {
  var topLeft: CGPoint
  var topRight: CGPoint
  var bottomRight: CGPoint
  var bottomLeft: CGPoint
}

enum POSType {
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

struct PictureShowPage {
  var texts: [Word]?
  var positions: [[Quadrilateral]]?
  var unknowWordsIndex: [Int]?
  var learningWordsIndex: [Int]?
  var definitions: [String:(word: String, definitions: [POSType:[String]])]?
}

// MARK: - LearedWords Structure

struct Word {
  var texts: String
  var pos: POSType
}
