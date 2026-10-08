//
//  TextFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class TextFilter {
  func textFilter(from page: PageContent) async -> ([Word],[Int],[String:(word: String, definitions: [POSType: [String]])]) {
    let formartToWords = FormatToWords(from: page)
    let lemmatization = Lemmatization()
    let LFilter = LearnedWordFilter()
    let AIFilter = PossibleAIFilter(background: UserSettings.shared.backgroundSummary)
    
    let (posTagedWords, range) = formartToWords.tagging()
    
    let caseFixedWords = formartToWords.wordsFilterFix(words: posTagedWords, ranges: range)
    
    let definitions = WordsDefinite().definition(caseFixedWords)
    
    let posFixed = formartToWords.fixPOS(words: caseFixedWords, definitions: definitions)
    
    let formated = lemmatization.morphy(words: posFixed)
    
    let unknowWordsIndex = LFilter.filter(lemmaedWords: formated, definitions: definitions)
    
    let possibleKnownFiltered = await AIFilter.possibleAIFilter(words: posFixed, unknownWordsIndex: unknowWordsIndex)
    //print(formated.map{$0.map{$0.texts}})
    //print(formated.count)
    //print(page.positions?.count)
    //print(unknowWordsIndex)
    
    return (posFixed,
            possibleKnownFiltered,
            definitions)
  }
}
