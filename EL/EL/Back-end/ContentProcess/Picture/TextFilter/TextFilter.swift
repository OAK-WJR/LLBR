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
  private let LFilter = LearnedWordFilter()
  
  func textFilter(from page: PageContent ) -> ([Word],[Int],[String:(word: String, definitions: [POSType:[String]])]) {
    let startTime = Date()
    
    let pos_tagedStartTime = Date()
    let pos_taged = pos_tagging.tagging(from: page)
    let pos_tagedTime = Date().timeIntervalSince(pos_tagedStartTime)
    
    let getDefinitionStartTime = Date()
    let definitions = WordsDefinite().definition(pos_taged)
    let posFixed = pos_tagging.fixPOS(words: pos_taged, definitions: definitions)
    let getDefinitionTime = Date().timeIntervalSince(getDefinitionStartTime)
    
    let lemmatizationStartTime = Date()
    let formated = lemmatization.morphy(words: posFixed)
    let lemmatizationTime = Date().timeIntervalSince(lemmatizationStartTime)
    
    let filterStartTime = Date()
    let unknowWordsIndex = LFilter.filter(lemmaedWords: formated, originalWords: posFixed)
    let filterTime = Date().timeIntervalSince(filterStartTime)
    
    let totalTime = Date().timeIntervalSince(startTime)
    
    print("POS Tagging Time: \(pos_tagedTime) seconds")
    print("Definition Time: \(getDefinitionTime) seconds")
    print("Lemmatization Time: \(lemmatizationTime) seconds")
    print("Filtering Time: \(filterTime) seconds")
    print("Total Time: \(totalTime) seconds")
    
    return (posFixed.map{Word(texts: $0.texts.lowercased(), pos: $0.pos)},
            unknowWordsIndex,
            definitions)
  }
}
