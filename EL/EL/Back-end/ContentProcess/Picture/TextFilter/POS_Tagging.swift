//
//  POS_Tagging.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

// POS = Part-Of-Speech

import Foundation
import NaturalLanguage

class POS_Tagging {
  func tagging(from page: PageContent) -> [Word] {
    let words = page.texts
    let sentencesRange = page.pointer.sentencePointer
    
    var sentences = [String]()

    for range in sentencesRange {
      let sentenceWords = words[range!].joined(separator: " ")
        sentences.append(sentenceWords)
    }
    
    
    var allWords: [Word] = [Word(texts: "", pos: .other)]
    
    var all = [String]()
    for sentence in sentences {
      let tagger = NLTagger(tagSchemes: [.lexicalClass])
      tagger.string = sentence
      
      tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
        if let tag = tag?.rawValue {
          all.append(String(sentence[tokenRange]))
          if tag == "Whitespace" {
            allWords.append(Word(texts: "", pos: .other))
          } else {
            let wordsPOS = Set(["Noun", "Verb", "Adjective", "Adverb", "Pronoun", "Determiner", "OtherWord", "Particle", "Preposition", "Conjunction", "Interjection", "Classifier", "Idiom", "Dash", "WordJoiner", "OtherPunctuation"])
            if wordsPOS.contains(tag) {
              let specificWords = ["\'s", "\'re", "\'ll", "n\'t"]
              let originalWord = String(sentence[tokenRange])
              if !specificWords.contains(originalWord) {
                var lemmaWord = originalWord
                
                let taggerL = NLTagger(tagSchemes: [.lemma])
                taggerL.string = originalWord
                let (lemma, _) = taggerL.tag(at: originalWord.startIndex, unit: .word, scheme: .lemma)
                if let lemma = lemma {
                  lemmaWord = lemma.rawValue
                }
                
                allWords[allWords.count - 1].texts += lemmaWord
                allWords[allWords.count - 1].pos = convertStringToPOSType(tag: tag)
              }
            }
          }
        }
        return true
      }
      allWords.append(Word(texts: "", pos: .other))
    }
    return (allWords)
  }
  
  public func convertStringToPOSType(tag: String) -> POSType {
    switch tag {
    case "Noun":
      return .noun
    case "Verb":
      return .verb
    case "Adjective":
      return .adjective
    case "Adverb":
      return .adverb
    case "Pronoun":
      return .pronoun
    case "Determiner":
      return .determiner
    case "OtherWord":
      return .other
    default:
      return .other
    }
  }
}
