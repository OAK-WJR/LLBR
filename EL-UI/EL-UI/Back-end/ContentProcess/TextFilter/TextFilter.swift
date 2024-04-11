//
//  TextFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class TextFilter {
  func textFilter(from page: PageContent ) -> ([Word],[Int],[String:(word: String, definitions: [POSType: [String]])]) {
    let formartToWords = FormatToWords(from: page)
    let lemmatization = Lemmatization()
    let LFilter = LearnedWordFilter()
    
    let startTime = Date()
    
    let pos_tagedStartTime = Date()
    let (posTagedWords, range) = formartToWords.tagging()
    let pos_tagedTime = Date().timeIntervalSince(pos_tagedStartTime)
    
    let caseFixedWords = formartToWords.wordsFilterFix(words: posTagedWords, ranges: range)
    
    let getDefinitionStartTime = Date()
    let definitions = WordsDefinite().definition(caseFixedWords)
    let getDefinitionTime = Date().timeIntervalSince(getDefinitionStartTime)
    
    let posFixed = formartToWords.fixPOS(words: caseFixedWords, definitions: definitions)
    
    let lemmatizationStartTime = Date()
    let formated = lemmatization.morphy(words: posFixed)
    let lemmatizationTime = Date().timeIntervalSince(lemmatizationStartTime)
    
    let filterStartTime = Date()
    let unknowWordsIndex = LFilter.filter(lemmaedWords: formated, originalWords: posFixed)
    let filterTime = Date().timeIntervalSince(filterStartTime)
    
    let totalTime = Date().timeIntervalSince(startTime)
    
    print(formated.map{$0.map{$0.texts}})
    print(formated.count)
    print(page.positions?.count)
    print(unknowWordsIndex)
    print("\n")
    print("POS Tagging Time: \(pos_tagedTime) seconds")
    print("Definition Time: \(getDefinitionTime) seconds")
    print("Lemmatization Time: \(lemmatizationTime) seconds")
    print("Filtering Time: \(filterTime) seconds")
    print("Total Time: \(totalTime) seconds")
    
    return (posFixed,
            unknowWordsIndex,
            definitions)
  }
}
