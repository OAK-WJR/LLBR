//
//  UnknowWords.swift
//  EL
//
//  Created by WJR on 1/6/24.
//

import Foundation
import SQLite3

class UnknowWordsDatabase {
  var db: OpaquePointer?
  
  init() {
    openDatabase()
    createTablesIfNeeded()
  }
  
  func openDatabase() {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let finalDatabaseURL = documentsURL.appendingPathComponent("UnknowWords.db")
    
    if !fileManager.fileExists(atPath: finalDatabaseURL.path) {
      let bundleDatabaseURL = Bundle.main.url(forResource: "UnknowWords", withExtension: "db")!
      do {
        try fileManager.copyItem(at: bundleDatabaseURL, to: finalDatabaseURL)
      } catch {
        print("Could not copy database from bundle to document directory: \(error)")
        return
      }
    }
    
    if sqlite3_open(finalDatabaseURL.path, &db) != SQLITE_OK {
      print("Error opening database")
    }
  }
  
  func createTablesIfNeeded() {
    let createFilterWordsTableString = """
      CREATE TABLE IF NOT EXISTS FilterWords (
          word TEXT PRIMARY KEY NOT NULL
      );
      """
    
    let createWordsTableString = """
      CREATE TABLE IF NOT EXISTS Words (
          word TEXT PRIMARY KEY NOT NULL,
          study_count INTEGER DEFAULT 0,
          frequency INTEGER DEFAULT 0,
          added_time DATETIME DEFAULT CURRENT_TIMESTAMP,
          modified_time DATETIME DEFAULT CURRENT_TIMESTAMP
      );
      """
    
    let createWordOccurrencesTableString = """
      CREATE TABLE IF NOT EXISTS WordOccurrences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word TEXT NOT NULL,
          bookIndex TEXT NOT NULL,
          pageIndex INTEGER NOT NULL,
          occurrence_time DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (word) REFERENCES Words(word)
      );
      """
    
    createTable(createTableString: createFilterWordsTableString)
    createTable(createTableString: createWordsTableString)
    createTable(createTableString: createWordOccurrencesTableString)
  }

  private func createTable(createTableString: String) {
    var createTableStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(createTableStatement) == SQLITE_DONE {
        print("Table created successfully.")
      } else {
        print("Table could not be created.")
      }
    } else {
      print("CREATE TABLE statement could not be prepared.")
    }
    sqlite3_finalize(createTableStatement)
  }
  
  func add(words: [String], bookIndex: String, pageIndex: Int) {
    let insertFilterWordsStatementString = "INSERT OR IGNORE INTO FilterWords (word) VALUES (?);"
    let insertWordsStatementString = "INSERT INTO Words (word, frequency, added_time, modified_time) VALUES (?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT(word) DO UPDATE SET frequency = frequency + 1, modified_time = CURRENT_TIMESTAMP;"
    let insertWordOccurrencesStatementString = "INSERT OR IGNORE INTO WordOccurrences (word, bookIndex, pageIndex) VALUES (?, ?, ?);"
    
    sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
    var statement: OpaquePointer?
    
    for word in words {
      // Insert or ignore in FilterWords
      if sqlite3_prepare_v2(db, insertFilterWordsStatementString, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (word as NSString).utf8String, -1, nil)
        sqlite3_step(statement)
        sqlite3_reset(statement)
      }
      
      // Insert or update in Words
      if sqlite3_prepare_v2(db, insertWordsStatementString, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (word as NSString).utf8String, -1, nil)
        sqlite3_step(statement)
        sqlite3_reset(statement)
      }
      
      // Insert or ignore in WordOccurrences
      if sqlite3_prepare_v2(db, insertWordOccurrencesStatementString, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, (word as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (bookIndex as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 3, Int32(pageIndex))
        sqlite3_step(statement)
        sqlite3_reset(statement)
      }
    }
    
    sqlite3_exec(db, "END TRANSACTION;", nil, nil, nil)
    sqlite3_finalize(statement)
    
    showAllWords()
  }
  
  func remove(words: [String]) {
    let deleteStatementString = "DELETE FROM FilterWords WHERE word = ?;"
    
    sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
    var deleteStatement: OpaquePointer?
    
    for word in words {
      if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
        sqlite3_bind_text(deleteStatement, 1, (word as NSString).utf8String, -1, nil)
        
        if sqlite3_step(deleteStatement) != SQLITE_DONE {
          print("Could not delete word: \(word)")
        }
        sqlite3_reset(deleteStatement)
      } else {
        print("DELETE statement could not be prepared.")
      }
    }
    
    sqlite3_exec(db, "END TRANSACTION;", nil, nil, nil)
    sqlite3_finalize(deleteStatement)
  }
  
  func getWords(forBookIndex bookIndex: String) -> [String] {
    var words: [String] = []
    let queryStatementString = "SELECT DISTINCT word FROM WordOccurrences WHERE bookIndex = ?;"
    var queryStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(queryStatement, 1, (bookIndex as NSString).utf8String, -1, nil)
      
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let word = String(cString: sqlite3_column_text(queryStatement, 0))
        words.append(word)
      }
    } else {
      print("SELECT statement could not be prepared")
    }
    
    sqlite3_finalize(queryStatement)
    return words
  }
  
  func filter(words: [Word], bookIndex: String?, pageIndex: Int?) -> [Int] {
    let isUpdate: Bool = (bookIndex != nil && pageIndex != nil)
    var filteredWordsIndex: [Int] = []
    
    executeStatement("BEGIN TRANSACTION;")
    
    for (index, word) in words.enumerated() {
      let lowercasedWord = word.texts.lowercased()
      
      if checkWordInUserLearned(word: lowercasedWord) {
        filteredWordsIndex.append(index)
      }
      
      if isUpdate {
        updateOrInsertWord(word: lowercasedWord)
        insertOccurrence(word: lowercasedWord, bookIndex: bookIndex, pageIndex: pageIndex)
      }
    }
    
    executeStatement("END TRANSACTION;")
    
    return filteredWordsIndex
  }
  
  private func checkWordInUserLearned(word: String) -> Bool {
    let checkStatementString = "SELECT word FROM FilterWords WHERE word COLLATE NOCASE = ?;"
    var checkStatement: OpaquePointer?
    defer { sqlite3_finalize(checkStatement) }
    
    if sqlite3_prepare_v2(db, checkStatementString, -1, &checkStatement, nil) == SQLITE_OK {
      let utf8Word = strdup(word)
      sqlite3_bind_text(checkStatement, 1, utf8Word, -1, nil)
      return sqlite3_step(checkStatement) == SQLITE_ROW
    } else {
      print("Error preparing query: \(String(cString: sqlite3_errmsg(db)))")
    }
    return false
  }
  
  private func updateOrInsertWord(word: String) {
    let updateOrInsertString = """
        INSERT INTO Words (word, frequency) VALUES (?, 1)
        ON CONFLICT(word) DO UPDATE SET frequency = frequency + 1, modified_time = CURRENT_TIMESTAMP;
        """
    executeStatement(updateOrInsertString, word: word)
  }
  
  private func insertOccurrence(word: String, bookIndex: String?, pageIndex: Int?) {
    let insertOccurrenceStatementString = "INSERT INTO WordOccurrences (word, bookIndex, pageIndex) VALUES (?, ?, ?);"
    executeStatement(insertOccurrenceStatementString, word: word, bookIndex: bookIndex, pageIndex: pageIndex)
  }
  
  private func executeStatement(_ sql: String, word: String? = nil, bookIndex: String? = nil, pageIndex: Int? = nil) {
    var statement: OpaquePointer?
    defer { sqlite3_finalize(statement) }
    
    if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
      if let word = word {
        sqlite3_bind_text(statement, 1, word, -1, nil)
      }
      if let bookIndex =
          bookIndex, let index = pageIndex {
        sqlite3_bind_text(statement, 2, bookIndex, -1, nil)
        sqlite3_bind_int(statement, 3, Int32(index))
      }
      
      if sqlite3_step(statement) != SQLITE_DONE {
        print("Error executing statement: \(sql)")
      }
    } else {
      print("Error preparing statement: \(sql)")
    }
  }
  
  func showAllWords() -> [String] {
    var words: [String] = []
    
    let queryStatementString = "SELECT word FROM FilterWords;"
    var queryStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let word = String(cString: sqlite3_column_text(queryStatement, 0))
        words.append(word)
      }
    } else {
      print("SELECT statement could not be prepared")
    }
    
    sqlite3_finalize(queryStatement)
    
    return words
  }
}
