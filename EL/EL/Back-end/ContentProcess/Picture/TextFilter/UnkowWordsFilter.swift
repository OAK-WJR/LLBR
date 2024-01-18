//
//  UnkowWords.swift
//  EL
//
//  Created by WJR on 1/16/24.
//

import Foundation

class UnkowWordsFilter {
  func filter(originalWords: [Word], bookIndex: String?, pageIndex: Int?) -> [Int] {
    let learnedWordsFilterWordsIndex = Set(UnknowWordsDatabase().filter(words: originalWords, bookIndex: bookIndex, pageIndex: pageIndex)).sorted()
    return learnedWordsFilterWordsIndex
  }
}
