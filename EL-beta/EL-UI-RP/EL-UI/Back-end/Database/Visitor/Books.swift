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
final class BooksDatabase {
  // Database connection pointer
  var db: OpaquePointer?
  let databaseQueue = DispatchQueue(label: "com.books.databaseQueue")
  static let shared = BooksDatabase()
  
  // Initialize the database connection
  init() {
    openDatabase()
    createIndexTableIfNeeded()
    getBooksInfo() { tables in
      print(tables)
      if !tables.map({ $0.name }).contains("dairy") {
        print("Need to create 'dairy' database")
        self.createTable(named: "dairy")
        
        var images: [CroppingImage] = []
        for i in 1...3 {
          guard let path = Bundle.main.path(forResource: String(i), ofType: "jpg") else { continue }
          if let image = UIImage(contentsOfFile: path) {
            images.append(CroppingImage(id: 0, image: image))
          }
        }
        print(images.count)
        
        if !images.isEmpty {
          self.addOriginal(originals: images, to: "dairy", chapterId: 0)
          print("Successfully loaded images into the 'dairy' table.")
        } else {
          print("No images found to load into the 'dairy' table.")
        }
      }
    }
  }

  
  //MARK: - Top-level functions - Initialization
  
  func openDatabase() {
    let fileURL = try! FileManager.default
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent("Books.db")
    
    databaseQueue.sync {
      if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
        print("Error opening database")
      } else {
        print("Successfully opened connection to database")
        // Set a busy timeout so a brief lock does not fail right away
        sqlite3_busy_timeout(db, 5000)
        // Switch to WAL mode so reads and writes are less likely to block each other
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "PRAGMA journal_mode=WAL;", -1, &stmt, nil) == SQLITE_OK {
          _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
      }
    }
  }

  func createIndexTableIfNeeded() {
    let createTableString = """
      CREATE TABLE IF NOT EXISTS IndexTable(
          name TEXT PRIMARY KEY NOT NULL,
          coverImage BLOB,
          addTime DATETIME DEFAULT CURRENT_TIMESTAMP,
          finalChangeTime DATETIME,
          pageNumber INTEGER
      );
      """
    var stmt: OpaquePointer?
    if sqlite3_prepare_v2(db, createTableString, -1, &stmt, nil) == SQLITE_OK {
      if sqlite3_step(stmt) != SQLITE_DONE {
        print("IndexTable could not be created.")    // Don't write "Diary" here anymore
      }
    } else {
      print("CREATE TABLE IndexTable could not be prepared.")
    }
    sqlite3_finalize(stmt)
  }

  // MARK: - Top-level functions - General operations
  func addOperation(_ data: Any, in tableName: String, chapterId: Int) {
    updateFinalChangeTime(named: tableName)
    updatePageNumber(named: tableName, change: "+")
    addOriginal(originals: [data], to: tableName, chapterId: chapterId)
  }

  func changeOperation(_ elementType: ElementType, _ newData: Any, at index: Int, from tableName: String) {
    updateFinalChangeTime(named: tableName)
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
    updateFinalChangeTime(named: tableName)
    updatePageNumber(named: tableName, change: "-")
    switch elementType {
    case .original:
      deleteOriginal(at: index, from: tableName)
    case .crop:
      deleteCrop(at: index, from: tableName)
    case .content:
      deleteContent(at: index, from: tableName)
    }
  }
  
  func getOperation(_ elementType: ElementType, at indexes: [Int], from tableName: String) -> Any? {
    switch elementType {
    case .original:
      return getOriginal(at: indexes, from: tableName)
    case .crop:
      return getCrop(at: indexes, from: tableName)
    case .content:
      return getContent(at: indexes, from: tableName)
    }
  }
  
  // MARK: - Top-level functions - Table operations

  // 1.1 Create a new table and update the index table
  func createTable(named tableName: String) {
    // First, try to create the new table
    let createTableString = """
      CREATE TABLE IF NOT EXISTS \(tableName) (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        ChapterId INTEGER,
      
        EntryDate DATETIME,
        Type TEXT,
        Original BLOB,
        Crop TEXT,
        Words TEXT,
        Positions TEXT,
        Pointer TEXT
      );
      """
    var createTableStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(createTableStatement) == SQLITE_DONE {
        print("\(tableName) table successfully created.")
        
        updateIndexTable(with: tableName)
      } else {
        print("\(tableName) table could not be created.")
      }
    } else {
      print("CREATE TABLE statement could not be prepared.")
    }
    sqlite3_finalize(createTableStatement)
  }

  private func updateIndexTable(with tableName: String) {
    let insertIndexString = """
      INSERT INTO IndexTable (name, addTime, finalChangeTime, pageNumber) VALUES (?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0);
      """
    var insertIndexStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, insertIndexString, -1, &insertIndexStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertIndexStatement, 1, (tableName as NSString).utf8String, -1, nil)
      
      if sqlite3_step(insertIndexStatement) == SQLITE_DONE {
        print("Successfully inserted \(tableName) into IndexTable.")
      } else {
        print("Could not insert \(tableName) into IndexTable.")
      }
    } else {
      print("INSERT INTO IndexTable statement could not be prepared.")
    }
    sqlite3_finalize(insertIndexStatement)
  }

  // 1.2 Rename a table and update the index table
  func changeTableName(from oldTableName: String, to newTableName: String) {
    // Prepare the SQL statement to rename a table
    let renameTableString = "ALTER TABLE \(oldTableName) RENAME TO \(newTableName);"
    var renameTableStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, renameTableString, -1, &renameTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(renameTableStatement) == SQLITE_DONE {
        print("Table \(oldTableName) successfully renamed to \(newTableName).")
        
        updateIndexTableForRename(from: oldTableName, to: newTableName)
      } else {
        print("Could not rename table \(oldTableName) to \(newTableName).")
      }
    } else {
      print("ALTER TABLE statement could not be prepared.")
    }
    sqlite3_finalize(renameTableStatement)
  }

  private func updateIndexTableForRename(from oldTableName: String, to newTableName: String) {
    let updateIndexString = """
      UPDATE IndexTable SET name = ?, finalChangeTime = CURRENT_TIMESTAMP WHERE name = ?;
      """
    var updateIndexStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, updateIndexString, -1, &updateIndexStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateIndexStatement, 1, (newTableName as NSString).utf8String, -1, nil)
      sqlite3_bind_text(updateIndexStatement, 2, (oldTableName as NSString).utf8String, -1, nil)
      
      if sqlite3_step(updateIndexStatement) == SQLITE_DONE {
        print("IndexTable successfully updated for \(oldTableName) to \(newTableName).")
      } else {
        print("Could not update IndexTable for \(oldTableName) to \(newTableName).")
      }
    } else {
      print("UPDATE IndexTable statement could not be prepared.")
    }
    sqlite3_finalize(updateIndexStatement)
  }

  // 1.3 Delete a table and update the index table
  func deleteTable(named tableName: String) {
    // Prepare the SQL statement to delete a table
    let deleteTableString = "DROP TABLE IF EXISTS \(tableName);"
    var deleteTableStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, deleteTableString, -1, &deleteTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(deleteTableStatement) == SQLITE_DONE {
        print("Table \(tableName) successfully deleted.")
        
        removeFromIndexTable(tableName: tableName)
      } else {
        print("Could not delete table \(tableName).")
      }
    } else {
      print("DROP TABLE statement could not be prepared.")
    }
    sqlite3_finalize(deleteTableStatement)
  }

  private func removeFromIndexTable(tableName: String) {
    let removeFromIndexString = "DELETE FROM IndexTable WHERE name = ?;"
    var removeFromIndexStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, removeFromIndexString, -1, &removeFromIndexStatement, nil) == SQLITE_OK {
      // Bind the table name to the SQL statement
      sqlite3_bind_text(removeFromIndexStatement, 1, (tableName as NSString).utf8String, -1, nil)
      
      if sqlite3_step(removeFromIndexStatement) == SQLITE_DONE {
        print("Record for \(tableName) successfully removed from IndexTable.")
      } else {
        print("Could not remove record for \(tableName) from IndexTable.")
      }
    } else {
      print("DELETE FROM IndexTable statement could not be prepared.")
    }
    sqlite3_finalize(removeFromIndexStatement)
  }
  
  // 1.4 Update the cover
  func addOrUpdateCoverForTable(named tableName: String, coverImage: UIImage) {
    // Convert UIImage to Data
    guard let imageData = coverImage.pngData() else {
      print("Error converting image to PNG data")
      return
    }
    
    // Check whether a cover record already exists
    let checkExistenceString = "SELECT EXISTS(SELECT 1 FROM IndexTable WHERE name = ? LIMIT 1);"
    var checkExistenceStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, checkExistenceString, -1, &checkExistenceStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(checkExistenceStatement, 1, (tableName as NSString).utf8String, -1, nil)
      
      var exists: Bool = false
      if sqlite3_step(checkExistenceStatement) == SQLITE_ROW {
        exists = sqlite3_column_int(checkExistenceStatement, 0) != 0
      }
      sqlite3_finalize(checkExistenceStatement)
      
      if exists {
        let updateCoverString = "UPDATE IndexTable SET coverImage = ?, finalChangeTime = CURRENT_TIMESTAMP WHERE name = ?;"
        var updateCoverStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateCoverString, -1, &updateCoverStatement, nil) == SQLITE_OK {
          sqlite3_bind_blob(updateCoverStatement, 1, (imageData as NSData).bytes, Int32(imageData.count), nil)
          sqlite3_bind_text(updateCoverStatement, 2, (tableName as NSString).utf8String, -1, nil)
          
          if sqlite3_step(updateCoverStatement) == SQLITE_DONE {
            print("Successfully updated cover for \(tableName).")
          } else {
            print("Could not update cover for \(tableName).")
          }
          sqlite3_finalize(updateCoverStatement)
        }
      } else {
        let insertCoverString = "INSERT INTO IndexTable (name, coverImage, addTime, finalChangeTime, pageNumber) VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0);"
        var insertCoverStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertCoverString, -1, &insertCoverStatement, nil) == SQLITE_OK {
          sqlite3_bind_text(insertCoverStatement, 1, (tableName as NSString).utf8String, -1, nil)
          sqlite3_bind_blob(insertCoverStatement, 2, (imageData as NSData).bytes, Int32(imageData.count), nil)
          
          if sqlite3_step(insertCoverStatement) == SQLITE_DONE {
            print("Successfully added cover for \(tableName).")
          } else {
            print("Could not add cover for \(tableName).")
          }
          sqlite3_finalize(insertCoverStatement)
        }
      }
    } else {
      print("CHECK EXISTENCE statement could not be prepared.")
    }
  }

  // 1.5 Read the Index table to get the basic data of all other tables
  func getBooksInfo(completion: @escaping ([BookInfo]) -> Void) {
    let queryString = "SELECT name, coverImage, addTime, finalChangeTime, pageNumber FROM IndexTable;"
    var statement: OpaquePointer?
    var bookCovers = [BookInfo]()
    
    if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
      while sqlite3_step(statement) == SQLITE_ROW {
        let name = String(cString: sqlite3_column_text(statement, 0))
        
        let coverImageData = sqlite3_column_blob(statement, 1)
        let coverImageSize = sqlite3_column_bytes(statement, 1)
        let coverImage: UIImage? = coverImageData != nil ? UIImage(data: Data(bytes: coverImageData!, count: Int(coverImageSize))) : nil
        
        let addTimeString = String(cString: sqlite3_column_text(statement, 2))
        let finalOpenTimeString = String(cString: sqlite3_column_text(statement, 3))
        let pageNumber = Int(sqlite3_column_int(statement, 4))
        
        let dateFormatter = ISO8601DateFormatter()
        let addTime = dateFormatter.date(from: addTimeString) ?? Date()
        let finalOpenTime = dateFormatter.date(from: finalOpenTimeString) ?? Date()
        
        let bookCover = BookInfo(name: name, coverImage: coverImage, addTime: addTime, finalOpenTime: finalOpenTime, pageNumber: pageNumber)
        bookCovers.append(bookCover)
      }
      sqlite3_finalize(statement)
    } else {
      if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
        print("Error preparing select: \(error)")
      }
    }
    completion(bookCovers)
  }
  
  // 1.6 Update the last-modified time
  func updateFinalChangeTime(named tableName: String) {
    let updateString = """
      UPDATE IndexTable SET finalChangeTime = CURRENT_TIMESTAMP WHERE name = ?;
      """
    var updateStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, updateString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, (tableName as NSString).utf8String, -1, nil)
      
      if sqlite3_step(updateStatement) == SQLITE_DONE {
        print("Successfully updated final change time for \(tableName).")
      } else {
        print("Could not update final change time for \(tableName).")
      }
    } else {
      print("UPDATE statement could not be prepared.")
    }
    sqlite3_finalize(updateStatement)
  }

  // 1.7 Update the page count
  func updatePageNumber(named tableName: String, change: String) {
    var updateString = String()
    
    if change == "+" {
      updateString = "UPDATE IndexTable SET pageNumber = pageNumber + 1 WHERE name = ?;"
    } else if change == "-" {
      updateString = "UPDATE IndexTable SET pageNumber = GREATEST(0, pageNumber - 1) WHERE name = ?;"
    }
    
    var updateStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, updateString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, (tableName as NSString).utf8String, -1, nil)
      
      if sqlite3_step(updateStatement) == SQLITE_DONE {
        if change == "+" {
          print("Successfully incremented page number for \(tableName).")
        } else if change == "-" {
          print("Successfully decremented page number for \(tableName), ensuring it does not go below 0.")
        }
      } else {
        print("Could not update page number for \(tableName).")
      }
    } else {
      print("UPDATE statement could not be prepared.")
    }
    sqlite3_finalize(updateStatement)
  }

  
  // 1.8 List all indexes of a Book table
  func getAllIds(from tableName: String, chapterId: Int?) -> [Int] {
    databaseQueue.sync {
      var ids = [Int]()
      
      var queryString = ""
      if let chapterId = chapterId {
        queryString = "SELECT ID FROM \(tableName) WHERE ChapterId = ?;"
      } else {
        queryString = "SELECT ID FROM \(tableName);"
      }
      
      var queryStatement: OpaquePointer?
      if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        if let chapterId = chapterId {
          sqlite3_bind_int(queryStatement, 1, Int32(chapterId))
        }
        
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
      print(ids)
      return ids
    }
  }
  
  func getAllChapterIds(from tableName: String) -> [(Int, [Int])] {
    databaseQueue.sync {
      var chapterDict = [Int: [Int]]()
      let queryString = "SELECT ChapterId, ID FROM \(tableName);"
      
      var queryStatement: OpaquePointer?
      
      // Prepare the query statement
      if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        // Loop over each row of the query result
        while sqlite3_step(queryStatement) == SQLITE_ROW {
          let chapterId = Int(sqlite3_column_int(queryStatement, 0))
          let id = Int(sqlite3_column_int(queryStatement, 1))
          
          // If this chapter ID already exists, append; otherwise create a new array
          if chapterDict[chapterId] != nil {
            chapterDict[chapterId]?.append(id)
          } else {
            chapterDict[chapterId] = [id]
          }
        }
      } else {
        if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
          print("Error preparing select: \(error)")
        }
      }
      
      // Release the query statement object
      sqlite3_finalize(queryStatement)
      
      // Convert the dictionary into an array of tuples and return it
      return chapterDict.map { ($0.key, $0.value) }
    }
  }

  // MARK: - Helper functions - Original data operations

  // 2.1 Add Type and Original content (supports batch insert)
  public func addOriginal(originals: [Any], to tableName: String, chapterId: Int) {
    databaseQueue.sync {
      let queryString = "INSERT INTO \(tableName) (EntryDate, Type, Original, ChapterId) VALUES (datetime('now', 'localtime'), ?, ?, ?);"
      var statement: OpaquePointer?
      
      // Begin the transaction
      if sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db))
        //print("Could not begin transaction. Error: \(errmsg)")
        return
      }
      
      if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
        for original in originals {
          // Make sure original is a CroppingImage and unwrap its image property
          guard let croppingImage = original as? CroppingImage,
                let unwrappedImage = croppingImage.image else {
            print("Invalid original data: \(original)")
            continue
          }
          
          // Set the type to UIImage
          let type = "UIImage"
          
          // Convert the UIImage to binary data
          guard let originalData = unwrappedImage.jpegData(compressionQuality: 1.0) else {
            print("Failed to process image data for item: \(croppingImage)")
            continue
          }
          
          // Bind the SQL parameters
          sqlite3_bind_text(statement, 1, (type as NSString).utf8String, -1, nil)
          sqlite3_bind_blob(statement, 2, (originalData as NSData).bytes, Int32(originalData.count), nil)
          sqlite3_bind_int(statement, 3, Int32(chapterId))
          
          // Run the insert
          if sqlite3_step(statement) == SQLITE_DONE {
            print("Successfully inserted row.")
          } else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Could not insert row. Error: \(errmsg)")
          }
          
          // Reset the statement for the next insert
          sqlite3_reset(statement)
        }
        sqlite3_finalize(statement)
      } else {
        if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
          print("Failed to prepare insert statement. Error: \(error)")
        }
      }
      
      // Commit the transaction
      if sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db))
        //print("Could not commit transaction. Error: \(errmsg)")
      }
      
      // processData function modified to support each element of a batch insert
      func processData(type: String, for value: Any) -> Data? {
        switch type {
        case "UIImage":
          return (value as! UIImage).jpegData(compressionQuality: 1)
        default:
          return nil
        }
      }
    }
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
    databaseQueue.sync {
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
            results.append((type, originalImage))
          }
        }
      } else {
        if let error = String(cString: sqlite3_errmsg(db), encoding: .utf8) {
          print("Error preparing select: \(error)")
        }
      }
      sqlite3_finalize(queryStatement)
      
      print(results.count)
      return results
    }
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
    databaseQueue.sync {
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
    databaseQueue.sync {
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
    databaseQueue.sync {
      sqlite3_close(db)
    }
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
