//
//  Attributes.swift
//  EL
//
//  Created by WJR on 11/10/23.
//

import Foundation
import UIKit

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

enum Direction {
  case up
  case down
  case left
  case right
  case none
}

struct InterfaceData {
  static let screen = UIScreen.main.bounds
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
  var postions: [Any]
  var pointer: Pointer
}

// MARK: - LearedWords Structure


struct Word {
  var texts: String
  var pos: POSType
}
