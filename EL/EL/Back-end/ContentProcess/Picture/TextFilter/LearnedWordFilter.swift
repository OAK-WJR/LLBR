//
//  LearnedWordFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class LearnedWordFilter {
  func filter(lemmaedWords: [[Word]], originalWords: [Word]) -> [Int] {
    let learnedWordsFilterWordsIndex = LearedWordsDatabase().filter(words: lemmaedWords)
    return Set(learnedWordsFilterWordsIndex).sorted()
  }
}
