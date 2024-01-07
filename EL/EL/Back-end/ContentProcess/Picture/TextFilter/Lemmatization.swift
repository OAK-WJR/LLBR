//
//  Lemmatization.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

import Foundation

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
             ("ing", "")],
      ADJ: [("er", ""),
            ("est", ""),
            ("er", "e"),
            ("est", "e")],
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
      if let exceptions = exceptionMap[word.pos]?[word.texts] {
        lemmatizedWords.append(exceptions.map{Word(texts: $0, pos: word.pos)})
      } else {
        let substitutions = morphologicalSubstitutions[word.pos, default: []]
        let forms = substitutions.compactMap { old, new -> String? in
          if word.texts.hasSuffix(old) {
            return String(word.texts.dropLast(old.count)) + new
          }
          return nil
        }
        lemmatizedWords.append([word] + forms.map { Word(texts: $0, pos: word.pos) })
      }
    }
    
    return lemmatizedWords
  }
}
