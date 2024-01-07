//
//  TextFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class TextFilter {
  
  private let pos_tagging = POS_Tagging()
  private let lemmatization = Lemmatization()
  private let filter = LearnedWordFilter()
  
  func textFilter(from page: PageContent ) -> ([Word],[Int]) {
    let pos_taged = pos_tagging.tagging(from: page)
    let formated = lemmatization.morphy(words: pos_taged)
    let filtered = filter.filter(from: formated)
    return (pos_taged.map{Word(texts: $0.texts.lowercased(), pos: $0.pos)}, filtered)
  }
}
