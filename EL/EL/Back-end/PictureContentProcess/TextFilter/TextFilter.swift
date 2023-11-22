//
//  TextFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class TextFilter {
  
  init(pageContent: PageContent) {
    let process = PC_Preprocessing(pageContent: pageContent)
    let anlysis = POS_Analysis()
    let filter = LearnedWordFilter()
  }
  
  func prepare(from page: PageContent ) -> [String] {
    process =
  }
  
  func
}
