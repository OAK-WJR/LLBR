//
//  Attributes.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import Foundation

// MARK: - Basic Definitions

//Quadrilateral box around a word
struct Quadrilateral {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint
}

//Part-of-speech type
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
}

// MARK: - Book Structures

struct Pointer {
  var phrasePointer: [Range<Int>?]
  var sentencePointer: [Range<Int>?]
}

//Content info for one page
struct PageContent {
  var texts: [String]
  var postions: [Any]
  var pointer: Pointer
}

// MARK: - LearedWords Structure


struct Word {
  var texts: String
  var pos: POSType
}
