//
//  TextFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class TextFilter {
  
  let pos_tagging = POS_Tagging()
  let lemmatization = Lemmatization()
  let filter = LearnedWordFilter()
  
  func TextFilter(from page: PageContent ) -> ([Word?],[Word?]) {
    var pos_taged = pos_tagging.tagging(from: page)
    var formated = lemmatization.lemmatize(pos_taged)
    var filtered = filter.filter(from: formated)
    return (pos_taged, filtered)
  }
}
