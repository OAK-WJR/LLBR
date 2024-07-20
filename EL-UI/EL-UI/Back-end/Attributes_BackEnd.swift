//
//  Attributes_BackEnd.swift
//  EL-UI
//
//  Created by WJR on 3/23/24.
//

import Foundation

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

struct Word: Codable {
  var texts: String
  var pos: POSType
}

struct Quadrilateral: Codable, Equatable {
  var topLeft: CGPoint
  var topRight: CGPoint
  var bottomRight: CGPoint
  var bottomLeft: CGPoint
}

struct Pointer {
  var phrasePointer: [Range<Int>?]
  var sentencePointer: [Range<Int>?]
}

struct PageContent {
  var texts: [String]
  var positions: [Any]?
  var pointer: Pointer
}
