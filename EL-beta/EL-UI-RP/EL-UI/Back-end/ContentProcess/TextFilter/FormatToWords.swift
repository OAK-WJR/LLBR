//
//  POS_Tagging.swift
//  EL
//
//  Created by WJR on 11/12/23.
//

// POS = Part-Of-Speech

import Foundation
import NaturalLanguage

class FormatToWords {
  let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
  
  var sentences: [String]
  
  init(from page: PageContent) {
    let words = page.texts
    let sentencesRange = page.pointer.sentencePointer
    
    self.sentences = [String]()
    
    for range in sentencesRange {
      let sentenceWords = words[range!].joined(separator: " ")
      self.sentences.append(sentenceWords)
    }
  }
  
  func tagging() -> (words: [Word], ranges: [[Range<String.Index> : Int]]) {
    var allWords: [Word] = [Word(texts: "", pos: .other)]
    var allRanges: [[Range<String.Index> : Int]] = []
    
    for sentence in sentences {
      var sentenceRange: [Range<String.Index> : Int] = [:]
      
      //print(sentence)
      tagger.string = sentence
      tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
        if let tag = tag?.rawValue {
          if tag == "Whitespace" {
            let texts = allWords[allWords.count - 1].texts
            let pattern = "-+$"
            allWords[allWords.count - 1].texts = texts.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            
            allWords.append(Word(texts: "", pos: .other))
          } else {
            let wordsPOS = Set(["Noun", "Verb", "Adjective", "Adverb", "Pronoun", "Determiner", "OtherWord", "Particle", "Preposition", "Conjunction", "Interjection", "Classifier", "Idiom", "WordJoiner", "OtherPunctuation", "Dash"])
            if wordsPOS.contains(tag) {
              let specificWords = ["\'s", "\'re", "\'ll", "\'m", "\'t", "n\'t", "\'d"]
              let originalWord = String(sentence[range])
              if !specificWords.contains(originalWord.lowercased()) {
                allWords[allWords.count - 1].texts += originalWord
                if allWords[allWords.count - 1].pos == .other {
                  allWords[allWords.count - 1].pos = convertStringToPOSType(tag: tag)
                }
                
                sentenceRange[range] = allWords.count - 1
              }
            } else {
              //print("\(String(sentence[range])):\(tag)")
            }
          }
        }
        return true
      }
      
      if allWords[allWords.count - 1].texts.hasSuffix(".") {
        allWords[allWords.count - 1].texts.removeLast()
      }
      
      allWords.append(Word(texts: "", pos: .other))
      allRanges.append(sentenceRange)
    }
    return (allWords.dropLast(), allRanges)
  }
  
  func wordsFilterFix(words: [Word], ranges: [[Range<String.Index>: Int]]) -> [Word] {
    var newWords = words
    for (index, sentence) in sentences.enumerated() {
      tagger.string = sentence
      let tags: [NLTag] = [.personalName, .placeName, .organizationName]
      
      if sentence.areAllWordsCapitalized() {
        tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .nameType, options: []) { tag, range in
          if let wordIndex = ranges[index][range] {
            
            if let tag = tag, tags.contains(tag) {
              if tag == .personalName {
                print("\(newWords[wordIndex].texts): \(tag.rawValue): 000 -> \"\"")
                newWords[wordIndex].texts = ""
              } else {
                let specialWord = String(sentence[range])
                let caseFixedWord = specialWord.capitalized
              
                print("\(newWords[wordIndex].texts): \(tag.rawValue): 001 -> \(caseFixedWord)")
                newWords[wordIndex].texts = caseFixedWord
              }
            } else {
              print("\(newWords[wordIndex].texts): \(tag!.rawValue): 01 -> \(newWords[wordIndex].texts.lowercased())")
              newWords[wordIndex].texts = newWords[wordIndex].texts.lowercased()
            }
            
          }
          
          return true
        }
      } else {
        var isFirstWord = true
        tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .nameType, options: []) { tag, range in
          if let wordIndex = ranges[index][range] {
            if let tag = tag, tags.contains(tag) {
              
              if tag == .personalName {
                print("\(newWords[wordIndex].texts): \(tag.rawValue): 100 -> \"\"")
                newWords[wordIndex].texts = ""
              } else {
                print("\(newWords[wordIndex].texts): \(tag.rawValue): 101 -> \(newWords[wordIndex].texts)")
              }
            } else {
              if isFirstWord {
                isFirstWord = false
                let firstWord = String(sentence[range]).lowercased()
                
                print("\(newWords[wordIndex].texts): \(tag!.rawValue): 110 -> \(firstWord)")
                newWords[wordIndex].texts = firstWord
              } else {
                print("\(newWords[wordIndex].texts): \(tag!.rawValue): 111 -> \(newWords[wordIndex].texts)")
              }
            }
          }
          
          return true
        }
        
        isFirstWord = true
      }
    }
//    print(newWords.map{$0.texts})
    return newWords
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

extension String {
  func areAllWordsCapitalized() -> Bool {
    let pattern = "\\b\\p{L}"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
    
    let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
    
    for match in matches {
      if let range = Range(match.range, in: self) {
        let firstLetter = self[range]
        if firstLetter.lowercased() == firstLetter {
          return false
        }
      }
    }
    
    return true
  }
}
