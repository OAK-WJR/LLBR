//
//  Preprocessing.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

//PC = PageContent
class PC_Preprocessing {
  var pageText: [String]
  var pagePostion: [Any]
  
  init(pageContent: PageContent?) {
    if let content = pageContent {
      self.pageText = content.texts
    }
  }
  
  func removePunctuation() -> [String] {
      // Code to remove punctuation
  }
  func lemmatize() -> [String] {
      // Code to lemmatize words
  }
}
