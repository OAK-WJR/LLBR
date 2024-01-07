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
    getAllTablesName() { tables in
      if !tables.contains("diary") {
        print("Need to create 'diary' database")
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
    Original BLOB,
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
  
  func getOperation(_ elementType: ElementType, at index: [Int], from tableName: String) -> Any? {
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
      Crop TEXT,
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
  func getAllTablesName(completion: @escaping ([String]) -> Void) {
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
  func getAllIds(from tableName: String) -> [Int] {
    var ids = [Int]()
    let queryString = "SELECT ID FROM \(tableName);"

    var queryStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = sqlite3_column_int(queryStatement, 0)
        ids.append(Int(id))
      }
    } else {
      if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
        print("Error preparing select: \(error)")
      }
    }
    sqlite3_finalize(queryStatement)

    return ids
  }

  // MARK: - Helper functions - Original data operations

  // 2.1 Add Type and Original content
  public func addOriginal(original: Any, to tableName: String) -> sqlite3_int64 {
    let type = getType(of: original)
    guard let originalData = processData(type: type, for: original) else {
        print("Failed to process original data")
        return -1
    }
    let queryString: String
    if tableName.lowercased() == "diary" {
        queryString = "INSERT INTO \(tableName) (EntryDate, Type, Original) VALUES (datetime('now', 'localtime'), ?, ?);"
    } else {
        queryString = "INSERT INTO \(tableName) (Type, Original) VALUES (?, ?);"
    }
    
    var statement: OpaquePointer?
    if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
        if tableName.lowercased() == "diary" {
            sqlite3_bind_text(statement, 1, (type as NSString).utf8String, -1, nil)
            sqlite3_bind_blob(statement, 2, (originalData as NSData).bytes, Int32(originalData.count), nil)
        } else {
            sqlite3_bind_text(statement, 1, (type as NSString).utf8String, -1, nil)
            sqlite3_bind_blob(statement, 2, (originalData as NSData).bytes, Int32(originalData.count), nil)
        }
        if sqlite3_step(statement) == SQLITE_DONE {
            print("Successfully inserted row.")
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Could not insert row. Error: \(errmsg)")
        }
        sqlite3_finalize(statement)
    } else {
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
  public func getOriginal(at index: [Int], from tableName: String) -> [(type: String?, original: UIImage?)] {
    var results: [(type: String?, original: UIImage?)] = []

    let querySQL: String
    let indexString = index.map(String.init).joined(separator: ", ")
    querySQL = "SELECT Type, Original FROM \(tableName) WHERE ID IN (\(indexString));"
    print(querySQL)
    var queryStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        if let typeCStr = sqlite3_column_text(queryStatement, 0),
           let originalBlob = sqlite3_column_blob(queryStatement, 1) {
          let originalBlobLength = sqlite3_column_bytes(queryStatement, 1)
          let type = String(cString: typeCStr)
          let data = Data(bytes: originalBlob, count: Int(originalBlobLength))
          let originalImage = UIImage(data: data)
          print("Type: \(type), Image Data Length: \(originalBlobLength)")
          results.append((type, originalImage))
        }
      }
    } else {
      if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
        print("Error preparing select: \(error)")
      }
    }
    sqlite3_finalize(queryStatement)

    print(results)
    return results
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
  public func getCrop(at index: [Int], from tableName: String) -> [Any]? {
    // Run the SQL to query crop content here and parse it by Type
    // Return the parsed crop
    return nil
  }

  // MARK: - Helper functions - Words, Positions and Pointer operations

  // 4.1 Add Words, Positions and Pointer content
  public func addContent(at index: Int, content: PageContent, to tableName: String) {
    let wordsText = content.texts.joined(separator: " ")
    let positionsText = encodePositions(content.positions as! [[Quadrilateral]])
    let pointerText = encodePointer(content.pointer)
    
    let insertStatementString = "UPDATE \(tableName) SET Words = ?, Positions = ?, Pointer = ? WHERE ID = ?;"

    var insertStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      
      let utf8WordsText = strdup(wordsText)
      sqlite3_bind_text(insertStatement, 1, utf8WordsText, -1, nil)
      
      let utf8PositionsText = strdup(positionsText)
      sqlite3_bind_text(insertStatement, 2, utf8PositionsText, -1, free)
      
      let utf8PointerText = strdup(pointerText)
      sqlite3_bind_text(insertStatement, 3, utf8PointerText, -1, free)
      sqlite3_bind_int(insertStatement, 4, Int32(index))
      
      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row.")
      } else {
        print("SQLite Error: \(String(cString: sqlite3_errmsg(db)))")
      }
      sqlite3_finalize(insertStatement)
    } else {
      print("INSERT statement could not be prepared.")
    }
  }
  
  private func encodePositions(_ positions: [[Quadrilateral]]) -> String {
    return positions.map { quadrilaterals in
      quadrilaterals.map { quadrilateral in
        "{\(quadrilateral.topLeft.x),\(quadrilateral.topLeft.y);" +
        "\(quadrilateral.topRight.x),\(quadrilateral.topRight.y);" +
        "\(quadrilateral.bottomRight.x),\(quadrilateral.bottomRight.y);" +
        "\(quadrilateral.bottomLeft.x),\(quadrilateral.bottomLeft.y)}"
      }.joined(separator: "|")
    }.joined(separator: "/")
  }
  
  private func encodePointer(_ pointer: Pointer) -> String {
    let phrasePointerText = pointer.phrasePointer.map { range -> String in
      if let range = range {
        return "\(range.lowerBound)-\(range.upperBound)"
      } else {
        return "nil"
      }
    }.joined(separator: ",")
    
    let sentencePointerText = pointer.sentencePointer.map { range -> String in
      if let range = range {
        return "\(range.lowerBound)-\(range.upperBound)"
      } else {
        return "nil"
      }
    }.joined(separator: ",")
    
    return "\(phrasePointerText)|\(sentencePointerText)"
  }

  // 4.2 Update Words, Positions and Pointer content
  public func changeContent(at index: Int, newContent: PageContent, in tableName: String) {
    // Run the SQL to update words and positions content here
  }

  // 4.3 Delete Words, Positions and Pointer content
  public func deleteContent(at index: Int, from tableName: String) {
    // Run the SQL to delete words and positions content here
  }

  // 4.4 Read Words, Positions and Pointer content
  public func getContent(at index: [Int], from tableName: String) -> [PageContent?] {
    var pageContents: [PageContent?] = []
    
    let idList = index.map(String.init).joined(separator: ",")
    let queryStatementString = "SELECT Words, Positions, Pointer FROM \(tableName) WHERE ID IN (\(idList));"
    
    var queryStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        if let wordsCString = sqlite3_column_text(queryStatement, 0),
           let positionsCString = sqlite3_column_text(queryStatement, 1),
           let pointerCString = sqlite3_column_text(queryStatement, 2) {
          let wordsText = String(cString: wordsCString)
          let positionsText = String(cString: positionsCString)
          let pointerText = String(cString: pointerCString)
          
          let words = wordsText.components(separatedBy: " ")
          let positions = decodePositions(positionsText)
          let pointer = decodePointer(pointerText)
          
          let pageContent = PageContent(texts: words, positions: positions, pointer: pointer)
          pageContents.append(pageContent)
        } else {
          pageContents.append(nil)
        }
      }
      sqlite3_finalize(queryStatement)
    } else {
      print("SELECT statement could not be prepared.")
    }
    
    return pageContents
  }
  
  private func decodePositions(_ text: String) -> [[Quadrilateral]] {
    return text.split(separator: "/").map { quadrilateralGroup in
      quadrilateralGroup.split(separator: "|").compactMap { quadrilateralText in
        let points = quadrilateralText.dropFirst().dropLast().split(separator: ";").map { pointText -> CGPoint in
          let coordinates = pointText.split(separator: ",").compactMap { Double($0) }
          if coordinates.count == 2 {
            return CGPoint(x: coordinates[0], y: coordinates[1])
          } else {
            return CGPoint.zero
          }
        }
        if points.count == 4 {
          return Quadrilateral(topLeft: points[0], topRight: points[1], bottomRight: points[2], bottomLeft: points[3])
        } else {
          return nil
        }
      }
    }
  }
  
  private func decodePointer(_ text: String) -> Pointer {
    let parts = text.split(separator: "|")
    let phrasePointers = parts.indices.contains(0) ? decodeRanges(from: String(parts[0])) : []
    let sentencePointers = parts.indices.contains(1) ? decodeRanges(from: String(parts[1])) : []
    
    return Pointer(phrasePointer: phrasePointers, sentencePointer: sentencePointers)
  }

  private func decodeRanges(from text: String) -> [Range<Int>?] {
    return text.split(separator: ",").map { rangeText -> Range<Int>? in
      if rangeText == "nil" {
        return nil
      }
      let bounds = rangeText.split(separator: "-").compactMap { Int($0) }
      if bounds.count == 2 {
        return bounds[0]..<bounds[1]
      } else {
        return nil
      }
    }
  }
  
  //MARK: - Close database connection
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
