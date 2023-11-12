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

// MARK: - Book Structures

//Text info for the content of one page
struct PageContentText {
    var contents: [[[String]]]
}
//Position info for the content of one page
struct PageContentPosition {
    var contents: [[[Any]]]
}

//Content info for one page
struct PageContent {
  var text: PageContentText
  var postions: PageContentPosition
}
