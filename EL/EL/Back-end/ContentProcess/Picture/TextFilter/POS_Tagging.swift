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
      print(sentence)
      let tagger = NLTagger(tagSchemes: [.lexicalClass])
      tagger.string = sentence
      
      tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
        if let tag = tag?.rawValue {
          all.append(String(sentence[tokenRange]))
          if tag == "Whitespace" {
            let texts = allWords[allWords.count - 1].texts
            let pattern = "-+$"
            allWords[allWords.count - 1].texts = texts.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            
            allWords.append(Word(texts: "", pos: .other))
          } else {
            let wordsPOS = Set(["Noun", "Verb", "Adjective", "Adverb", "Pronoun", "Determiner", "OtherWord", "Particle", "Preposition", "Conjunction", "Interjection", "Classifier", "Idiom", "WordJoiner", "OtherPunctuation", "Dash"])
            if wordsPOS.contains(tag) {
              let specificWords = ["\'s", "\'re", "\'ll", "\'m", "\'t", "n\'t", "\'d"]
              let originalWord = String(sentence[tokenRange])
              if !specificWords.contains(originalWord) {
                allWords[allWords.count - 1].texts += originalWord
                if allWords[allWords.count - 1].pos == .other {
                  allWords[allWords.count - 1].pos = convertStringToPOSType(tag: tag)
                }
              }
            }
          }
        }
        return true
      }
      
      if allWords[allWords.count - 1].texts.hasSuffix(".") {
        allWords[allWords.count - 1].texts.removeLast()
      }
      
      allWords.append(Word(texts: "", pos: .other))
    }
    return (allWords.dropLast())
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
  
  func fixPOS(words: [Word], definitions: [String:(word: String, definitions: [POSType:[String]])]) -> [Word] {
    var fixedPOSWords = [Word]()
    for word in words {
      if ((definitions[word.texts.lowercased()]) != nil) {
        fixedPOSWords.append(word)
      } else {
        if ((definitions[word.texts.lowercased()]?.definitions[word.pos]) != nil) {
          fixedPOSWords.append(word)
        } else {
          fixedPOSWords.append(Word(texts: word.texts, pos: .other))
        }
      }
    }
    return fixedPOSWords
  }
}
