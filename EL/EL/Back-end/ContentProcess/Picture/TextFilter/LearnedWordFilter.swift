//
//  LearnedWordFilter.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

class LearnedWordFilter {
  func filter(from words: [[Word]]) -> [Int] {
    let filterWordsIndex = LearedWordsDatabase().filter(words)
    print(filterWordsIndex)
    return filterWordsIndex
  }
}
