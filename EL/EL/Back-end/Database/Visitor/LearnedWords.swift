//
//  LearnedWords.swift
//  EL
//
//  Created by WJR on 11/13/23.
//

import Foundation
import SQLite3

class LearedWordsDatabase {
  var db: OpaquePointer?
  
  init() {
    guard let path = Bundle.main.path(forResource: "wordFreq", ofType: "db") else {
      print("Database file not found in the app bundle")
      return
    }
    
    if sqlite3_open(path, &db) != SQLITE_OK {
      print("Error opening database")
    }
  }
  
  // MARK: - Main function - Add words
  
  func add(_ words: [Word]) {
    //splitForm = group the words with firstLetterClassification -> ([String:[String]], [String:[[Int]]])
    //Use splitForm[0] to add each new word to its own database
  }
  // MARK: - Main function - Remove words
  
  func remove(_ words: [Word]) {
    //splitForm = group the words with firstLetterClassification -> ([String:[String]], [String:[[Int]]])
    //Use splitForm[0] to delete the matching words from the database
  }
  //MARK: - Main function - Filter words
  
  func filter(_ words: [[Word]]) -> [Int] {
    //splitForm = group the words with firstLetterClassification -> ([String:[Word]], [String:[[Int]]])
    /*Ex: [Word(texts: "apple", pos: .noun),
     Word(texts: "banana", pos: .noun),
     Word(texts: "cat", pos: .noun),
     Word(texts: "act", pos: .noun),
     Word(texts: "camera", pos: .noun),
     Word(texts: "apple", pos: .noun)]
     */
    
    /*  ->["a":[Word(texts: "apple", pos: .noun), Word(texts: "act", pos: .noun)],
     "b":[Word(texts: "banana", pos: .noun)],
     "c":[Word(texts: "cat", pos: .noun), Word(texts: "camera", pos: .noun)]]
     */
    //  ->["a":[[0, 5], [3]], "b":[[1]], "c":[[2], [4]]
    
    
    //filtered = compare splitForm[0] with the words in the database and replace the ones found with an empty string "" -> [String:[String]]
    /*Ex: ["a":[Word(texts: "apple", pos: .noun), Word(texts: "act", pos: .noun)],
     "b":[Word(texts: "banana", pos: .noun)],
     "c":[Word(texts: "cat", pos: .noun), Word(texts: "camera", pos: .noun)]]
     */
    /*Database: ["apple":"noun",
     "banana":"noun",
     "act":"noun"]
     */
    
    //  ->["a":["", ""], "b":[""], "c":[Word(texts: "cat", pos: .noun), Word(texts: "camera", pos: .noun)]]
    
    
    //formated = use splitForm[1] to put filtered back into the original order
    //Ex: filtered = ["a":["", ""], "b":[""], "c":[Word(texts: "cat", pos: .noun), Word(texts: "camera", pos: .noun)]]
    //    splitForm[1]] = ["a":[[0, 5], [3]], "b":[[1]], "c":[[2], [4]]
    
    //  ->["", "", Word(texts: "cat", pos: .noun), "", Word(texts: "camera", pos: .noun), ""]
    
    
    //return formated
    let queue = DispatchQueue(label: "com.example.myqueue")
    var filteredWordsIndex: [Int] = []
    
    queue.sync {
      
      let uniqueWords = Set(words.flatMap { $0 }.map { $0.texts.lowercased() })
      print(uniqueWords)
      let wordString = uniqueWords.map { "'\($0)'" }.joined(separator: ",")
      
      let queryStatementString = "SELECT word FROM WordFreq WHERE id <= 3999 AND word IN (\(wordString));"
      
      var queryStatement: OpaquePointer?
      if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        var existingWords: Set<String> = []
        while sqlite3_step(queryStatement) == SQLITE_ROW {
          if let cString = sqlite3_column_text(queryStatement, 0) {
            let word = String(cString: cString)
            existingWords.insert(word)
          }
        }
        sqlite3_finalize(queryStatement)
        
        for (wordIndex, word) in words.enumerated() {
          print(wordIndex)
          var i = 0
          var filteredWord = false
          while !filteredWord && i < word.count {
            print(word[i].texts," ",word[i].pos)
            if existingWords.contains(word[i].texts.lowercased()) {
              filteredWord = true
            }
            i += 1
          }
          if !filteredWord {
            filteredWordsIndex.append(wordIndex)
          }
        }
      } else {
        print("Error preparing query: \(String(cString: sqlite3_errmsg(db)))")
      }
    }
    
    return filteredWordsIndex
  }
  
  // Close the database connection
  deinit {
    // Close the database connection here
    // e.g. sqlite3_close(db)
  }
}
