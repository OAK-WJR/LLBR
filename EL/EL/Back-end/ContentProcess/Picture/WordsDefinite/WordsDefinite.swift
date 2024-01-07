//
//  WordsDefinite.swift
//  EL
//
//  Created by WJR on 11/22/23.
//

import Foundation

class WordsDefinite {
  func definition(_ words: [Word]) -> [String:(word: String, definitions: [POSType:[String]])] {
    let texts = words.map { $0.texts }
    let allDefinitions: [String: String] = DictionaryDatabase().definition(texts)
    var definitions: [String:(word: String, definitions: [POSType:[String]])] = [:]
    
    for (word, definitionString) in allDefinitions {
      var wordDefinitions: [POSType: [String]] = [:]
      let definitionParts = definitionString.components(separatedBy: "\\n")
      var currentPOSType: POSType? = nil
      
      for part in definitionParts {
        if let posType = posStringInDefinition(part) {
          currentPOSType = posType
        } else {
          currentPOSType = .other
        }
        
        if let currentPOSType = currentPOSType {
          wordDefinitions[currentPOSType, default: []].append(part.trimmingCharacters(in: .whitespaces))
        }
      }
      
      definitions[word.lowercased()] = (word: word, definitions: wordDefinitions)
    }
    
    print(definitions)
    return definitions
  }
  
  private func posStringInDefinition(_ definitionPart: String) -> POSType? {
    let posMap: [String: POSType] = [
      "n.": .noun,
      "v.": .verb,
      "adj.": .adjective,
      "adv.": .adverb,
      "pron.": .pronoun,
      "prep.": .preposition,
      "conj.": .conjunction,
      "interj.": .interjection,
      "det.": .determiner,
      "oth.": .other
    ]
    
    for (key, value) in posMap {
      if definitionPart.starts(with: key) {
        return value
      }
    }
    return nil
  }
}
