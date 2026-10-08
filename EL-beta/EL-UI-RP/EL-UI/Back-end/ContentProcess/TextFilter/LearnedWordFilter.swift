//
//  LearnedWordFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class LearnedWordFilter {
  func filter(lemmaedWords: [[Word]], definitions: [String:(word: String, definitions: [POSType:[String]])]) -> [Int] {
    let learnedWordsFilterWordsIndex = LearedWordsDatabase().filter(words: lemmaedWords, definitions: definitions)
    return Set(learnedWordsFilterWordsIndex).sorted()
  }
}
