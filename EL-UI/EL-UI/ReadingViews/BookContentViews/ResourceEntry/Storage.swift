//
//  Storage.swift
//  EL-UI
//
//  Created by WJR on 4/9/24.
//

import SwiftUI
import SQLite3

class EditResourceDatabase {
  var db: OpaquePointer?
  
  init() {
    openDatabase()
    createOrderTable()
    createTable()
  }
  
  func openDatabase() {
    let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("croppingImages.sqlite")
    if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
      print("error opening database")
    }
  }
  
  func createTable() {
    let createTableString = """
        CREATE TABLE IF NOT EXISTS Images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        addTime TEXT,
        imageData BLOB,
        croppingData TEXT);
        """
    var createTableStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(createTableStatement) == SQLITE_DONE {
        print("Images table created.")
      } else {
        print("Images table could not be created.")
      }
    } else {
      print("CREATE TABLE statement could not be prepared.")
    }
    sqlite3_finalize(createTableStatement)
  }
  
  func createOrderTable() {
    let createOrderTableString = """
      CREATE TABLE IF NOT EXISTS ImageOrder(
      orderID INTEGER PRIMARY KEY AUTOINCREMENT,
      imageID INTEGER,
      FOREIGN KEY(imageID) REFERENCES Images(id));
      """
    var createOrderTableStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, createOrderTableString, -1, &createOrderTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(createOrderTableStatement) == SQLITE_DONE {
        print("ImageOrder table created.")
      } else {
        print("ImageOrder table could not be created.")
      }
    } else {
      print("CREATE TABLE statement for ImageOrder could not be prepared.")
    }
    sqlite3_finalize(createOrderTableStatement)
  }
  
  func fetchSortedIds() -> [Int] {
    let queryStatementString = "SELECT imageID FROM ImageOrder ORDER BY orderID;"
    var queryStatement: OpaquePointer? = nil
    var ids: [Int] = []
    
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = Int(sqlite3_column_int(queryStatement, 0))
        ids.append(id)
      }
    } else {
      let errmsg = String(cString: sqlite3_errmsg(db)!)
      print("error preparing select: \(errmsg)")
    }
    sqlite3_finalize(queryStatement)
    
    return ids
  }
  
  func insertImage(image: UIImage) {
    let insertStatementString = "INSERT INTO Images (addTime, imageData, croppingData) VALUES (?, ?, ?);"
    var insertStatement: OpaquePointer?
    
    // Convert UIImage to Data
    guard let imageData = image.pngData() else { return }
    
    let dateFormatter = ISO8601DateFormatter()
    let addTime = dateFormatter.string(from: Date())
    
    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, (addTime as NSString).utf8String, -1, nil)
      sqlite3_bind_blob(insertStatement, 2, (imageData as NSData).bytes, Int32(imageData.count), nil)
      sqlite3_bind_null(insertStatement, 3) // Cropping is not added yet
      
      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row.")
      } else {
        print("Could not insert row.")
      }
    } else {
      print("INSERT statement could not be prepared.")
    }
    sqlite3_finalize(insertStatement)
    
    let lastRowId = sqlite3_last_insert_rowid(db)
    let insertOrderStatementString = "INSERT INTO ImageOrder (imageID) VALUES (?);"
    var insertOrderStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, insertOrderStatementString, -1, &insertOrderStatement, nil) == SQLITE_OK {
      sqlite3_bind_int(insertOrderStatement, 1, Int32(lastRowId))
      
      if sqlite3_step(insertOrderStatement) == SQLITE_DONE {
        print("Successfully inserted order row.")
      } else {
        print("Could not insert order row.")
      }
    } else {
      print("INSERT statement for ImageOrder could not be prepared.")
    }
    sqlite3_finalize(insertOrderStatement)
  }
 
  func updateCroppingForImage(id: Int, cropping: Quadrilateral) {
    let updateStatementString = "UPDATE Images SET croppingData = ? WHERE id = ?;"
    var updateStatement: OpaquePointer?
    
    let croppingData = try! JSONEncoder().encode(cropping)
    let croppingString = String(data: croppingData, encoding: .utf8)!
    
    if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, (croppingString as NSString).utf8String, -1, nil)
      sqlite3_bind_int(updateStatement, 2, Int32(id))
      
      if sqlite3_step(updateStatement) == SQLITE_DONE {
        print("Successfully updated cropping.")
      } else {
        print("Could not update cropping.")
      }
    } else {
      print("UPDATE statement could not be prepared.")
    }
    sqlite3_finalize(updateStatement)
  }
  
  func fetchImages(ids: [Int]) -> [CroppingImage] {
    var results: [CroppingImage] = []
    
    let queryString = "SELECT id, imageData, croppingData FROM Images WHERE id IN (\(ids.map(String.init).joined(separator: ",")));"
    var queryStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = Int(sqlite3_column_int(queryStatement, 0))
        
        let imageDataBlob = sqlite3_column_blob(queryStatement, 1)
        let imageDataSize = sqlite3_column_bytes(queryStatement, 1)
        let imageData = Data(bytes: imageDataBlob!, count: Int(imageDataSize))
        guard let image = UIImage(data: imageData) else { continue }
        
        // Handle croppingDataString, which may be nil
        let croppingDataString: String?
        if let cString = sqlite3_column_text(queryStatement, 2) {
          croppingDataString = String(cString: cString)
        } else {
          croppingDataString = nil // or consider using a default value or skipping this loop iteration
        }
        
        // Decode based on the value of croppingDataString
        var cropping: Quadrilateral? = nil
        if let dataString = croppingDataString, let data = dataString.data(using: .utf8) {
          cropping = try? JSONDecoder().decode(Quadrilateral.self, from: data)
        }
        
        results.append(CroppingImage(id: id, image: image, cropping: cropping))
      }
    } else {
      print("SELECT statement could not be prepared")
    }
    sqlite3_finalize(queryStatement)
    
    return results
  }
}
