//
//  Lemmatization.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation
import NaturalLanguage
import UIKit

class Lemmatization {
  private let NOUN = POSType.noun, VERB = POSType.verb, ADJ = POSType.adjective, ADV = POSType.adverb, DET = POSType.determiner
  private var morphologicalSubstitutions: [POSType: [(String, String)]]
  private var exceptionMap: [POSType: [String: [String]]]
  
  init() {
    morphologicalSubstitutions = [
      NOUN: [("s", ""),
             ("ses", "s"),
             ("ves", "f"),
             ("xes", "x"),
             ("zes", "z"),
             ("ches", "ch"),
             ("shes", "sh"),
             ("men", "man"),
             ("ies", "y")],
      VERB: [("s", ""),
             ("ies", "y"),
             ("es", "e"),
             ("es", ""),
             ("ed", "e"),
             ("ed", ""),
             ("ing", "e"),
             ("ing", ""),
             ("\'t", ""),
             ("n\'t", "n")],
      ADJ: [("er", ""),
            ("est", ""),
            ("er", "e"),
            ("est", "e")],
      ADV: [("\'t", ""),
            ("n\'t", "")],
      DET: [("an", "a")]
    ]
    exceptionMap = [:]
    loadExceptionMap()
  }
  
  private func loadExceptionMap() { //from LEWords(LemmatizationExceptionWords)
    let fileMap = [ADJ: "adj", ADV: "adv", NOUN: "noun", VERB: "verb"]
    for (pos, suffix) in fileMap {
      if let filePath = Bundle.main.path(forResource: suffix, ofType: "exc") {
        if let content = try? String(contentsOfFile: filePath) {
          for line in content.components(separatedBy: "\n") {
            let terms = line.split(separator: " ").map(String.init)
            if terms.count > 1 {
              exceptionMap[pos, default: [:]][terms[0]] = Array(terms.dropFirst())
            }
          }
        }
      }
    }
  }
  
  func morphy(words: [Word]) -> [[Word]] {
    
    var lemmatizedWords: [[Word]] = []
    for word in words {
      let word = Word(texts: word.texts.lowercased(), pos: word.pos)
      if let exceptions = getExceptions(for: word) {
        lemmatizedWords.append(exceptions.map { Word(texts: $0, pos: word.pos) })
      } else {
        lemmatizedWords.append(lemmatizeWord(word))
      }
      print(word.texts, word.pos)
      print(lemmatizedWords.last)
    }
    
    return lemmatizedWords
  }
  
  private func getExceptions(for word: Word) -> [String]? {
    let posTypes: [POSType] = word.pos == .other ? [VERB, NOUN, ADJ, ADV, DET] : [word.pos]
    print(word.texts," ",posTypes)
    for pos in posTypes {
      if let exceptions = exceptionMap[pos]?[word.texts] {
        print(exceptions)
        return exceptions
      }
    }
    return nil
  }
  
  private func lemmatizeWord(_ word: Word) -> [Word] {
    var allForms: [Word] = [word]
    let posTypes: [POSType] = word.pos == .other ? [VERB, NOUN, ADJ, ADV, DET] : [word.pos]
    
    for pos in posTypes {
      let substitutions = morphologicalSubstitutions[pos, default: []]
      allForms += substitutions.compactMap { old, new -> String? in
        if word.texts.hasSuffix(old) {
          return String(word.texts.dropLast(old.count)) + new
        }
        return nil
      }.map { Word(texts: $0, pos: pos) }
    }
    
    return allForms
  }
}

extension String {
  var isBlank: Bool {
    let trimmedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedStr.isEmpty
  }
}
