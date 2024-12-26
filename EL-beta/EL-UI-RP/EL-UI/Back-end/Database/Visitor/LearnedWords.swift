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
  private let dbQueue = DispatchQueue(label: "com.unknownWords.databaseQueue") // Serial queue
  
  init() {
    openDatabase()
  }
  
  func openDatabase() {
    var isFirstTime = false
    
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let finalDatabaseURL = documentsURL.appendingPathComponent("LearnedWords.db")
    
    isFirstTime = !fileManager.fileExists(atPath: finalDatabaseURL.path)
    if isFirstTime {
      let bundleDatabaseURL = Bundle.main.url(forResource: "LearnedWords", withExtension: "db")!
      do {
        try fileManager.copyItem(at: bundleDatabaseURL, to: finalDatabaseURL)
      } catch {
        print("Could not copy database from bundle to document directory: \(error)")
        return
      }
    }
    
    if sqlite3_open(finalDatabaseURL.path, &db) != SQLITE_OK {
      print("Error opening database")
    } else {
      if isFirstTime {
        populateUserLearned()
      }
    }
  }
  
  private func populateUserLearned() {
    var freqDataBase = "BNC_Freq"
    var levelNum = 3999
    if let userEnglishLevel = UserSettings.shared.userEnglishLevel {
      switch userEnglishLevel.learningSystem {
      case .US:
        freqDataBase = "BNC_Freq"
      case .UK:
        freqDataBase = "COCA_Freq"
      }
      
      switch userEnglishLevel.vocabularyLevel {
      case .beginner:
        levelNum = 1000
      case .intermediate:
        levelNum = 3999
      case .advanced:
        levelNum = 6999
      }
    }
    let queryStatementString = "INSERT OR IGNORE INTO UserLearned (word, POS) SELECT word, POS FROM \(freqDataBase) WHERE id <= \(levelNum);"
    var queryStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      if sqlite3_step(queryStatement) == SQLITE_DONE {
        print("Successfully populated UserLearned table.")
      } else {
        let errmsg = String(cString: sqlite3_errmsg(db))
        print("Failure inserting into UserLearned: \(errmsg)")
      }
      sqlite3_finalize(queryStatement)
    } else {
      let errmsg = String(cString: sqlite3_errmsg(db))
      print("INSERT statement could not be prepared. Error: \(errmsg)")
    }
  }
  
  // MARK: - Main function - Add words
  
  func add(_ words: [[Word]]) {
    let insertStatementString = "INSERT OR IGNORE INTO UserLearned (word, POS) VALUES (?, ?);"
    
    sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
    var insertStatement: OpaquePointer?
    
    for forms in words {
      for form in forms {
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
          sqlite3_bind_text(insertStatement, 1, (form.texts as NSString).utf8String, -1, nil)
          sqlite3_bind_text(insertStatement, 2, (form.pos.stringValue as NSString).utf8String, -1, nil)
          
          if sqlite3_step(insertStatement) != SQLITE_DONE {
            print("Could not insert word: \(form.texts), POS: \(form.pos)")
          }
          sqlite3_reset(insertStatement)
        }
      }
    }
    
    sqlite3_exec(db, "END TRANSACTION;", nil, nil, nil)
    sqlite3_finalize(insertStatement)
  }
  
  // MARK: - Main function - Remove words
  
  func remove(_ words: [[Word]]) {
    let deleteStatementString = "DELETE FROM UserLearned WHERE word = ?;"
    
    sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
    var deleteStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
      let uniqueWords = Set(words.flatMap { $0 }.map { $0.texts })
      
      for word in uniqueWords {
        sqlite3_bind_text(deleteStatement, 1, (word as NSString).utf8String, -1, nil)
        
        if sqlite3_step(deleteStatement) != SQLITE_DONE {
          print("Could not delete word: \(word)")
        }
        sqlite3_reset(deleteStatement)
      }
      verifyWordsDeletion(words)
    } else {
      print("DELETE statement could not be prepared.")
    }
    
    sqlite3_exec(db, "END TRANSACTION;", nil, nil, nil)
    sqlite3_finalize(deleteStatement)
  }
  
  func verifyWordsDeletion(_ words: [[Word]]) {
    let wordConditions = words.flatMap { $0 }.map { "word = '\($0.texts.lowercased())'" }
    let whereCondition = wordConditions.joined(separator: " OR ")
    let queryStatementString = "SELECT word FROM UserLearned WHERE \(whereCondition);"
    
    var queryStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var remainingWords: [String] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        if let wordCString = sqlite3_column_text(queryStatement, 0) {
          let word = String(cString: wordCString)
          remainingWords.append(word)
        }
      }
      sqlite3_finalize(queryStatement)
      
      if remainingWords.isEmpty {
        print("All words have been successfully deleted.")
      } else {
        print("These words are still in the database: \(remainingWords.joined(separator: ", "))")
      }
    } else {
      print("Error preparing query: \(String(cString: sqlite3_errmsg(db)))")
    }
  }
  
  //MARK: - Main function - Filter words
  
  func filter(words: [[Word]], definitions: [String:(word: String, definitions: [POSType:[String]])]) -> [Int] {
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
      let wordString = uniqueWords.map { "'\($0)'" }.joined(separator: ",")
      
      let queryStatementString = "SELECT word FROM UserLearned WHERE word IN (\(wordString));"
      
      var queryStatement: OpaquePointer?
      if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        var existingWords: Set<String> = [""]
        while sqlite3_step(queryStatement) == SQLITE_ROW {
          if let cString = sqlite3_column_text(queryStatement, 0) {
            let word = String(cString: cString)
            existingWords.insert(word)
          }
        }
        sqlite3_finalize(queryStatement)
        
        for (wordIndex, word) in words.enumerated() {
          
          print(word)
          if word.count == 1 && word[0].texts.count <= 3 {
            if word[0].texts.count >= 2 && 
                definitions[word[0].texts.lowercased()]?.word == word[0].texts.lowercased() &&
                word[0].pos == .noun {
              print("yes")
            } else {
              print("pass")
              continue
            }
          }
          
          //print(wordIndex)
          var i = 0
          var filteredWord = false
          while !filteredWord && i < word.count {
            //print(word[i].texts," ",word[i].pos)
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
