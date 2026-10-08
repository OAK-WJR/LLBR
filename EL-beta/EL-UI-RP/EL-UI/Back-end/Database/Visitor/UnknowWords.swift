//
//  UnknowWords.swift
//  EL
//
//  Created by WJR on 1/6/24.
//

import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class UnknowWordsDatabase {
  static let shared = UnknowWordsDatabase()
  var db: OpaquePointer?
  private let dbQueue = DispatchQueue(label: "com.unknownWords.databaseQueue") // Serial queue
  
  init() {
    openDatabase()
    createTablesIfNeeded()
  }
  
  func openDatabase() {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let finalDatabaseURL = documentsURL.appendingPathComponent("UnknowWords.db")

    if !fileManager.fileExists(atPath: finalDatabaseURL.path) {
      if let bundleDatabaseURL = Bundle.main.url(forResource: "UnknowWords", withExtension: "db") {
        try? fileManager.copyItem(at: bundleDatabaseURL, to: finalDatabaseURL)
      }
    }

    // FULLMUTEX gives a single connection its own internal mutex too (to be safe)
    if sqlite3_open_v2(finalDatabaseURL.path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
      print("Error opening database")
      return
    }

    // Busy timeout (milliseconds)
    sqlite3_busy_timeout(db, 5000)

    // Switch to WAL
    var stmt: OpaquePointer?
    if sqlite3_prepare_v2(db, "PRAGMA journal_mode=WAL;", -1, &stmt, nil) == SQLITE_OK { _ = sqlite3_step(stmt) }
    sqlite3_finalize(stmt)
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
          FOREIGN KEY (word) REFERENCES Words(word),
          UNIQUE(word, bookIndex, pageIndex)
      );
      """
    
    createTable(createTableString: createFilterWordsTableString)
    createTable(createTableString: createWordsTableString)
    createTable(createTableString: createWordOccurrencesTableString)
  }

  private func createTable(createTableString: String) {
    dbQueue.sync {
      var createTableStatement: OpaquePointer? = nil
      if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
        if sqlite3_step(createTableStatement) == SQLITE_DONE {
          //        print("Table created successfully.")
        } else {
          print("Table could not be created.")
        }
      } else {
        print("UnknowWordsDatabase CREATE TABLE statement could not be prepared.")
      }
      defer { sqlite3_finalize(createTableStatement) }
    }
  }
  
  func add(words: [String], bookIndex: String, pageIndex: Int) {
    dbQueue.sync {
      let insertFilterWordsStatementString = "INSERT OR IGNORE INTO FilterWords (word) VALUES (?);"
      let insertWordsStatementString = """
              INSERT INTO Words (word, frequency, added_time, modified_time) VALUES (?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
              ON CONFLICT(word) DO UPDATE SET frequency = frequency + 1, modified_time = CURRENT_TIMESTAMP;
              """
      let insertWordOccurrencesStatementString = "INSERT OR IGNORE INTO WordOccurrences (word, bookIndex, pageIndex) VALUES (?, ?, ?);"
      
      // Begin the transaction
      sqlite3_exec(db, "BEGIN IMMEDIATE TRANSACTION;", nil, nil, nil)
      defer {
        if sqlite3_exec(db, "COMMIT;", nil, nil, nil) != SQLITE_OK {
          _ = sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
        }
      }
      
      defer { sqlite3_exec(db, "END TRANSACTION;", nil, nil, nil) }
      
      var filterStatement: OpaquePointer?
      var wordsStatement: OpaquePointer?
      var occurrencesStatement: OpaquePointer?
      
      // Precompile the SQL statements
      if sqlite3_prepare_v2(db, insertFilterWordsStatementString, -1, &filterStatement, nil) != SQLITE_OK {
        print("Error preparing insert statement for FilterWords")
        return
      }
      if sqlite3_prepare_v2(db, insertWordsStatementString, -1, &wordsStatement, nil) != SQLITE_OK {
        print("Error preparing insert statement for Words")
        sqlite3_finalize(filterStatement)
        return
      }
      if sqlite3_prepare_v2(db, insertWordOccurrencesStatementString, -1, &occurrencesStatement, nil) != SQLITE_OK {
        print("Error preparing insert statement for WordOccurrences")
        sqlite3_finalize(filterStatement)
        sqlite3_finalize(wordsStatement)
        return
      }
      
      defer {
        sqlite3_finalize(filterStatement)
        sqlite3_finalize(wordsStatement)
        sqlite3_finalize(occurrencesStatement)
      }
      
      // Insert the data
      for word in words {
        // Insert into the FilterWords table
        sqlite3_bind_text(filterStatement, 1, (word as NSString).utf8String, -1, nil)
        if sqlite3_step(filterStatement) != SQLITE_DONE {
          print("Error inserting into FilterWords: \(String(cString: sqlite3_errmsg(db)!))")
        }
        sqlite3_reset(filterStatement)
        
        // Insert or update the Words table
        sqlite3_bind_text(wordsStatement, 1, (word as NSString).utf8String, -1, nil)
        if sqlite3_step(wordsStatement) != SQLITE_DONE {
          print("Error inserting/updating Words: \(String(cString: sqlite3_errmsg(db)!))")
        }
        sqlite3_reset(wordsStatement)
        
        // Insert into the WordOccurrences table
        sqlite3_bind_text(occurrencesStatement, 1, (word as NSString).utf8String, -1, nil)
        sqlite3_bind_text(occurrencesStatement, 2, (bookIndex as NSString).utf8String, -1, nil)
        sqlite3_bind_int(occurrencesStatement, 3, Int32(pageIndex))
        if sqlite3_step(occurrencesStatement) != SQLITE_DONE {
          print("Error inserting into WordOccurrences: \(String(cString: sqlite3_errmsg(db)!))")
        }
        sqlite3_reset(occurrencesStatement)
      }
    }
  }
  
  
  func remove(words: [String]) {
    dbQueue.sync {
      let deleteStatementString = "DELETE FROM FilterWords WHERE word = ?;"
      
      sqlite3_exec(db, "BEGIN EXCLUSIVE TRANSACTION;", nil, nil, nil)
      var deleteStatement: OpaquePointer?
      
      for word in words {
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
          sqlite3_bind_text(deleteStatement, 1, (word as NSString).utf8String, -1, nil)
          
          if sqlite3_step(deleteStatement) != SQLITE_DONE {
            print("Could not delete word: \(word)")
          }
          sqlite3_reset(deleteStatement)
        } else {
          print("UnknowWordsDatabase DELETE statement could not be prepared.")
        }
      }
      
      defer { sqlite3_exec(db, "END TRANSACTION", nil, nil, nil) }
      defer { sqlite3_finalize(deleteStatement) }
    }
  }
  
  func getWords(forBookIndex bookIndex: String) -> [String] {
    dbQueue.sync {
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
        print("UnknowWordsDatabase SELECT statement could not be prepared")
      }
      
      defer { sqlite3_finalize(queryStatement) }
        
      return words
    }
  }
  
  func filter(words: [Word], bookIndex: String?, pageIndex: Int?) -> [Int] {
    dbQueue.sync {
      let isUpdate: Bool = (bookIndex != nil && pageIndex != nil)
      var filteredWordsIndex: [Int] = []
      
      sqlite3_exec(db, "BEGIN IMMEDIATE TRANSACTION;", nil, nil, nil)
      
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
      
      sqlite3_exec(db, "COMMIT;", nil, nil, nil)
      
      return filteredWordsIndex
    }
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
        sqlite3_bind_text(statement, 1, word, -1, SQLITE_TRANSIENT)
      }
      if let bookIndex =
          bookIndex, let index = pageIndex {
        sqlite3_bind_text(statement, 2, bookIndex, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 3, Int32(index))
      }
      
      if sqlite3_step(statement) != SQLITE_DONE {
        print("SQLite step failed: \(String(cString: sqlite3_errmsg(db))) | SQL: \(sql)")
      }
    } else {
      //print("Error preparing statement: \(sql)")
    }
  }
  
  func showAllWords() -> [String] {
    return dbQueue.sync {
      var words: [String] = []
      
      let queryStatementString = "SELECT word FROM FilterWords;"
      var queryStatement: OpaquePointer?
      
      if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        while sqlite3_step(queryStatement) == SQLITE_ROW {
          let word = String(cString: sqlite3_column_text(queryStatement, 0))
          words.append(word)
        }
      } else {
        print("UnknowWordsDatabase SELECT statement could not be prepared")
      }
      
      defer { sqlite3_finalize(queryStatement) }
      
      return words
    }
  }
  
  private func executeInsertStatement(_ sql: String, word: String, bookIndex: String? = nil, pageIndex: Int? = nil) {
    var statement: OpaquePointer?
    defer { sqlite3_finalize(statement) }
    if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
      sqlite3_bind_text(statement, 1, word, -1, nil)
      if let bookIndex = bookIndex, let pageIndex = pageIndex {
        sqlite3_bind_text(statement, 2, bookIndex, -1, nil)
        sqlite3_bind_int(statement, 3, Int32(pageIndex))
      }
      sqlite3_step(statement)
    } else {
      print("Error preparing statement: \(sql)")
    }
  }
}
