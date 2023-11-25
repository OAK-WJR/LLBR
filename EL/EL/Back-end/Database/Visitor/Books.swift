//
//  Books.swift
//  EL
//
//  Created by WJR on 11/11/23.
//

import SQLite3
import UIKit
import CoreMedia
import CoreGraphics

// Enum that tells the operation types apart
enum ElementType {
  case original
  case crop
  case content
}

// Database manager class
class BooksDatabase {
  // Database connection pointer
  var db: OpaquePointer?
  
  // Initialize the database connection
  init() {
    openDatabase()
    allTables() { tables in
      if tables.contains("diary") {
        self.createDiaryTableIfNeeded()
      }
    }
  }

  
  //MARK: - Top-level functions - Initialization
  
  func openDatabase() {
    let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent("Books.db")

    if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
      print("Error opening database")
      return
    }

    print("Successfully opened connection to database")
  }

  func createDiaryTableIfNeeded() {
    let createTableString = """
    CREATE TABLE IF NOT EXISTS diary(
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    EntryDate DATETIME,
    Type TEXT,
    Original TEXT,
    Crop TEXT,
    Words TEXT,
    Positions TEXT,
    Pointer TEXT);
    """

    var createTableStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(createTableStatement) != SQLITE_DONE {
        print("Diary table could not be created.")
      }
    } else {
      print("CREATE TABLE statement could not be prepared.")
    }
    sqlite3_finalize(createTableStatement)
  }

  // MARK: - Top-level functions - General operations
  func addOperation(_ data: Any, in tableName: String, completion: @escaping (sqlite3_int64) -> Void) {
    completion(addOriginal(original: data, to: tableName))
  }
  
  func changeOperation(_ elementType: ElementType, _ newData: Any, at index: Int, from tableName: String) {
    switch elementType {
    case .original:
      changeOriginal(at: index, newOriginal: newData as! PageContent, in: tableName)
    case .crop:
      changeCrop(at: index, newCrop: newData, in: tableName)
    case .content:
      changeContent(at: index, newContent: newData as! PageContent, in: tableName)
    }
  }
  
  func deleteOperation(_ elementType: ElementType, at index: Int, from tableName: String) {
    switch elementType {
    case .original:
      deleteOriginal(at: index, from: tableName)
    case .crop:
      deleteCrop(at: index, from: tableName)
    case .content:
      deleteContent(at: index, from: tableName)
    }
  }
  
  func getOperation(_ elementType: ElementType, at index: Int, from tableName: String) -> Any? {
    switch elementType {
    case .original:
      return getOriginal(at: index, from: tableName)
    case .crop:
      return getCrop(at: index, from: tableName)
    case .content:
      return getContent(at: index, from: tableName)
    }
  }
  
  // MARK: - Top-level functions - Table operations

  // 1.1 Create a new table
  func createTable(named tableName: String) {
    // Execute the SQL statement to create a new table
    let createTableString = """
    CREATE TABLE \(tableName) (
      ID INTEGER PRIMARY KEY,
      Type TEXT,
      Original BLOB,
      Crop BLOB,
      Words TEXT,
      Positions TEXT
      Pointer TEXT
    );
    """
    // Run the SQL to create the table here
  }

  // 1.2 Rename a table
  func changeTableName(from oldTableName: String, to newTableName: String) {
    // Execute the SQL statement to rename a table
    let renameTableString = "ALTER TABLE \(oldTableName) RENAME TO \(newTableName);"
    // Run the SQL to rename the table here
  }

  // 1.3 Delete a table
  func deleteTable(named tableName: String) {
    // Execute the SQL statement to delete a table
    let deleteTableString = "DROP TABLE IF EXISTS \(tableName);"
    // Run the SQL to delete the table here
  }
  
  // 1.4 List table names
  func allTables(completion: @escaping ([String]) -> Void) {
    let queryString = "SELECT name FROM sqlite_master WHERE type='table';"
    var statement: OpaquePointer?
    var tables = [String]()
    
    if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
      while sqlite3_step(statement) == SQLITE_ROW {
        let tableName = String(cString: sqlite3_column_text(statement, 0))
        tables.append(tableName)
      }
      sqlite3_finalize(statement)
    } else {
      if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
        print("Error preparing select: \(error)")
      }
    }
    completion(tables)
  }
  
  // 1.5 List all indexes
  func allIndex(from tableName: String) -> [Any] {
    var indexes = [String]()
    let queryString = "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ?;"

    var queryStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(queryStatement, 1, (tableName.lowercased() as NSString).utf8String, -1, nil)

      while sqlite3_step(queryStatement) == SQLITE_ROW {
        if let queryResultCol1 = sqlite3_column_text(queryStatement, 0) {
          let name = String(cString: queryResultCol1)
          indexes.append(name)
        }
      }
    } else {
      print("SELECT statement could not be prepared")
    }

    sqlite3_finalize(queryStatement)

    return indexes
  }

  // MARK: - Helper functions - Original data operations

  // 2.1 Add Type and Original content
  public func addOriginal(original: Any, to tableName: String) -> sqlite3_int64 {
    let type = getType(of: original)
    let originalData = processData(type: type, for: original)
    let queryString: String
    
    
    if tableName.lowercased() == "diary" {
      queryString = "INSERT INTO \(tableName) (EntryDate, Type, Original) VALUES (datetime('now', 'localtime'), ?, ?);"
    } else {
      queryString = "INSERT INTO \(tableName) (Type, Original) VALUES (?, ?);"
    }
    
    var statement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
      if tableName.lowercased() == "diary" {

        sqlite3_bind_text(statement, 2, (type as NSString).utf8String, -1, nil)
        sqlite3_bind_blob(statement, 3, (originalData! as NSData).bytes, Int32(originalData!.count), nil)

      } else {
        
        sqlite3_bind_text(statement, 1, (type as NSString).utf8String, -1, nil)
        sqlite3_bind_blob(statement, 2, (originalData! as NSData).bytes, Int32(originalData!.count), nil)
        
      }
      
      if sqlite3_step(statement) == SQLITE_DONE {
        print("Successfully inserted row.")
      } else {
        let errmsg = String(cString: sqlite3_errmsg(db))
        print("Could not insert row. Error: \(errmsg)")
        let index = allIndex(from: "diary")
        print("Indexs: \(String(describing: index))")
      }
      
      sqlite3_finalize(statement)
    } else {
      print("INSERT statement could not be prepared. Error: \(String(describing: sqlite3_errmsg(db)))")
      if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
        print("Failed to prepare insert statement. Error: \(error)")
      }
    }
    
    func processData(type: String, for value: Any) -> Data? {
      switch type {
      case "UIImage":
        return (value as! UIImage).jpegData(compressionQuality: 1)
      // Add more cases for each type you want to handle
      default:
        return nil
      }
    }
    
    return sqlite3_last_insert_rowid(db)
  }

  // 2.2 Update Type and Original content
  public func changeOriginal(at index: Int, newOriginal: Any, in tableName: String) {
    // Run the SQL to update content here
  }

  // 2.3 Delete Type and Original content
  public func deleteOriginal(at index: Int, from tableName: String) {
    // Run the SQL to delete content here
  }

  // 2.4 Read Type and Original content
  public func getOriginal(at index: Int, from tableName: String) -> (type: String?, original: Any?) {
    // Run the SQL to query content here and parse it by Type
    // Return Type and the parsed Original
    return (nil, nil)
  }

  // MARK: - Helper functions - Crop operations

  // 3.1 Add crop content
  public func addCrop(at index: Any?, crop: Any, to tableName: String) {
    // Run the SQL to insert crop content here
  }

  // 3.2 Update crop content
  public func changeCrop(at index: Int, newCrop: Any, in tableName: String) {
    // Run the SQL to update crop content here
  }

  // 3.3 Delete crop content
  public func deleteCrop(at index: Int, from tableName: String) {
    // Run the SQL to delete crop content here
  }

  // 3.4 Read crop content
  public func getCrop(at index: Int, from tableName: String) -> Any? {
    // Run the SQL to query crop content here and parse it by Type
    // Return the parsed crop
    return nil
  }

  // MARK: - Helper functions - Words, Positions and Pointer operations

  // 4.1 Add Words and Positions content
  public func addContent(at index: Any?, content: PageContent, to tableName: String) {
    // Run the SQL to insert words and positions content here
  }

  // 4.2 Update Words and Positions content
  public func changeContent(at index: Int, newContent: PageContent, in tableName: String) {
    // Run the SQL to update words and positions content here
  }

  // 4.3 Delete Words and Positions content
  public func deleteContent(at index: Int, from tableName: String) {
    // Run the SQL to delete words and positions content here
  }

  // 4.4 Read Words and Positions content
  public func getContent(at indexu: Int, from tableName: String) -> PageContent? {
    // Run the SQL to query words and positions content here and parse it by Type
    // Return the parsed words and positions
    return nil
  }

  // Close the database connection
  deinit {
      // Close the database connection here
      // e.g. sqlite3_close(db)
  }
  
  //MARK: - Utilities
  
  public func getType(of value: Any) -> String {
    switch value {
    case is UIImage:
      return "UIImage"
    // Add more types as needed
    default:
      return "Unknown"
    }
  }
}
