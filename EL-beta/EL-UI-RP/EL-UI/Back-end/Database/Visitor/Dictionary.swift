//
//  Dictionary.swift
//  EL
//
//  Created by WJR on 11/22/23.
//

import Foundation
import SQLite3

class DictionaryDatabase {
  var db: OpaquePointer?
  
  init() {
    guard let path = Bundle.main.path(forResource: "Dictionary", ofType: "db") else {
      print("Database file not found")
      return
    }
    
    if sqlite3_open(path, &db) != SQLITE_OK {
      if let error = String(validatingUTF8: sqlite3_errmsg(db)) {
        print("Error opening database: \(error)")
      }
    }
  }
  
  func definition(_ words: [String]) -> [String: String] {
    var results = [String: String]()
    var wordGroups = [String: [String]]()
    
    for word in words {
      let initial = String(word.first?.lowercased() ?? "_").rangeOfCharacter(from: CharacterSet.letters) == nil ? "SPECIAL_Words" : word.first!.uppercased() + "_Words"
      wordGroups[initial, default: []].append(word)
    }
    
    for (initial, groupWords) in wordGroups {
      let placeholders = groupWords.map { _ in "word COLLATE NOCASE = ?" }.joined(separator: " OR ")
      let queryString = "SELECT word, translation FROM \(initial) WHERE \(placeholders)"
      var statement: OpaquePointer?
      
      if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
        for (index, word) in groupWords.enumerated() {
          let utf8Word = strdup(word)
          sqlite3_bind_text(statement, Int32(index + 1), utf8Word, -1, free)
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
          let word = String(cString: sqlite3_column_text(statement, 0))
          let translation = String(cString: sqlite3_column_text(statement, 1))
          results[word] = translation
        }
        sqlite3_finalize(statement)
      } else {
        print("SELECT statement could not be prepared")
      }
    }
    
    return results
  }
  
  deinit {
    sqlite3_close(db)
  }
}
