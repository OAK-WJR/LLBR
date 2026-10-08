//
// Storage.swift
// EL-UI
//
// Created by WJR on 4/9/24.
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
        orderIndex INTEGER PRIMARY KEY AUTOINCREMENT,
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
 
 func dropTables(completion: @escaping () -> Void) {
  // SQL statement to drop the Images table
  let dropImagesTableString = "DROP TABLE IF EXISTS Images;"
  // SQL statement to drop the Details table
  let dropDetailsTableString = "DROP TABLE IF EXISTS ImageOrder;"
  
  var statement: OpaquePointer?
  
  // Start a transaction to ensure both drop operations are completed
  sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
  
  // Drop the Images table
  if sqlite3_prepare_v2(db, dropImagesTableString, -1, &statement, nil) == SQLITE_OK {
   if sqlite3_step(statement) == SQLITE_DONE {
    print("Images table has been dropped.")
   } else {
    print("Failed to drop Images table.")
   }
   sqlite3_finalize(statement) // Clean up the prepared statement
  } else {
   print("Failed to prepare DROP TABLE statement for Images.")
  }
  
  // Drop the Details table
  if sqlite3_prepare_v2(db, dropDetailsTableString, -1, &statement, nil) == SQLITE_OK {
   if sqlite3_step(statement) == SQLITE_DONE {
    print("Details table has been dropped.")
   } else {
    print("Failed to drop Details table.")
   }
   sqlite3_finalize(statement) // Clean up the prepared statement
  } else {
   print("Failed to prepare DROP TABLE statement for Details.")
  }
  
  // Commit the transaction
  sqlite3_exec(db, "COMMIT;", nil, nil, nil)
  completion()
 }
 
 func fetchSortedIds() -> [(id: Int, orderIndex: Int)] {
  let queryStatementString = "SELECT imageID, orderIndex FROM ImageOrder ORDER BY orderIndex;"
  var queryStatement: OpaquePointer? = nil
  var results: [(id: Int, orderIndex: Int)] = []
  
  if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
   while sqlite3_step(queryStatement) == SQLITE_ROW {
    let id = Int(sqlite3_column_int(queryStatement, 0))
    let orderIndex = Int(sqlite3_column_int(queryStatement, 1))
    results.append((id: id, orderIndex: orderIndex))
   }
  } else {
   let errmsg = String(cString: sqlite3_errmsg(db)!)
   print("Error preparing select: \(errmsg)")
  }
  sqlite3_finalize(queryStatement)
  
  return results
 }
 
 func insertImage(image: UIImage, atIndex: Int, completion: @escaping () -> Void) {
  let insertStatementString = "INSERT INTO Images (addTime, imageData, croppingData) VALUES (?, ?, ?);"
  var insertStatement: OpaquePointer?
  
  // Convert UIImage to Data
  guard let imageData = image.pngData() else { return }
  
  let dateFormatter = ISO8601DateFormatter()
  let addTime = dateFormatter.string(from: Date())
  
  // Begin the transaction
  sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
  
  // Insert the entry into the Images table
  if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
   sqlite3_bind_text(insertStatement, 1, (addTime as NSString).utf8String, -1, nil)
   sqlite3_bind_blob(insertStatement, 2, (imageData as NSData).bytes, Int32(imageData.count), nil)
   sqlite3_bind_null(insertStatement, 3) // Cropping is not added yet
   
   if sqlite3_step(insertStatement) == SQLITE_DONE {
    print("Successfully inserted row.")
   } else {
    print("Could not insert row.")
    sqlite3_finalize(insertStatement)
    sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
    completion()
    return
   }
  } else {
   print("INSERT statement could not be prepared.")
   sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
   completion()
   return
  }
  sqlite3_finalize(insertStatement)
  
  let lastRowId = sqlite3_last_insert_rowid(db)
  
  // If a position was given, update orderIndex
  if atIndex != -1 {
   // SQL statement: add 1 to orderIndex of every record whose orderIndex >= atIndex
   let updateOrderIndexSql = "UPDATE ImageOrder SET orderIndex = orderIndex + 1 WHERE orderIndex >= ?;"
   var updateOrderIndexStatement: OpaquePointer?
   
   // Prepare the SQL statement
   if sqlite3_prepare_v2(db, updateOrderIndexSql, -1, &updateOrderIndexStatement, nil) == SQLITE_OK {
    // Bind atIndex to the ? in the SQL statement
    sqlite3_bind_int(updateOrderIndexStatement, 1, Int32(atIndex))
    
    // Execute the SQL statement
    if sqlite3_step(updateOrderIndexStatement) != SQLITE_DONE {
     print("Error updating order indexes.")
     // Release the SQL statement object
     sqlite3_finalize(updateOrderIndexStatement)
     // Roll back the transaction
     sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
     completion()
     return
    }
    // Release the SQL statement object
    sqlite3_finalize(updateOrderIndexStatement)
   } else {
    print("UPDATE statement could not be prepared.")
    // Roll back the transaction
    sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
    completion()
    return
   }
  }
  
  // Insert the entry into the ImageOrder table
  let insertOrderStatementString = atIndex == -1 ?
  "INSERT INTO ImageOrder (imageID) VALUES (?);" :
  "INSERT INTO ImageOrder (imageID, orderIndex) VALUES (?, ?);"
  
  var insertOrderStatement: OpaquePointer?
  
  if sqlite3_prepare_v2(db, insertOrderStatementString, -1, &insertOrderStatement, nil) == SQLITE_OK {
   sqlite3_bind_int(insertOrderStatement, 1, Int32(lastRowId))
   
   if atIndex != -1 {
    sqlite3_bind_int(insertOrderStatement, 2, Int32(atIndex))
   }
   
   if sqlite3_step(insertOrderStatement) == SQLITE_DONE {
    print("Successfully inserted order row.")
   } else {
    print("Could not insert order row.")
    sqlite3_finalize(insertOrderStatement)
    sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
    completion()
    return
   }
  } else {
   print("INSERT statement for ImageOrder could not be prepared.")
   sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
   completion()
   return
  }
  sqlite3_finalize(insertOrderStatement)
  
  // Commit the transaction
  sqlite3_exec(db, "COMMIT;", nil, nil, nil)
  completion()
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
 
 func fetchImages(ids: [Int], completion: @escaping ([CroppingImage]) -> Void) {
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
  
  completion(results)
 }
 
 func deleteImages(startId: Int, quantity: Int, ids: [Int], completion: @escaping () -> Void) {
  guard let startIndex = ids.firstIndex(where: { $0 == startId }) else {
   print("Start ID not found in the list of IDs.")
   return
  }
  
  let deleteIds = Array(ids[startIndex..<min(startIndex + quantity, ids.count)])
  var startIndexOrder: Int32 = 0
  
  // Convert the IDs to delete into a string
  let deleteIdsString = deleteIds.map { String($0) }.joined(separator: ",")
  
  // Begin the transaction
  sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
  
  // First query and save the orderIndex of the images to delete
  let getIndexSql = "SELECT orderIndex FROM ImageOrder WHERE imageID = ?;"
  var getIndexStatement: OpaquePointer?
  
  if sqlite3_prepare_v2(db, getIndexSql, -1, &getIndexStatement, nil) == SQLITE_OK {
   sqlite3_bind_int(getIndexStatement, 1, Int32(startId))
   if sqlite3_step(getIndexStatement) == SQLITE_ROW {
    startIndexOrder = sqlite3_column_int(getIndexStatement, 0)
   }
   sqlite3_finalize(getIndexStatement)
  } else {
   let errmsg = String(cString: sqlite3_errmsg(db)!)
   print("Error preparing select orderIndex: \(errmsg)")
  }
  
  // Delete the entries from the ImageOrder table
  let deleteOrderSql = "DELETE FROM ImageOrder WHERE imageID IN (\(deleteIdsString));"
  var deleteOrderStatement: OpaquePointer?
  if sqlite3_prepare_v2(db, deleteOrderSql, -1, &deleteOrderStatement, nil) == SQLITE_OK {
   if sqlite3_step(deleteOrderStatement) != SQLITE_DONE {
    print("Error deleting order entries.")
   }
   sqlite3_finalize(deleteOrderStatement)
  } else {
   let errmsg = String(cString: sqlite3_errmsg(db)!)
   print("Error preparing delete order entries: \(errmsg)")
  }
  
  // Delete the entries from the Images table
  let deleteImageSql = "DELETE FROM Images WHERE id IN (\(deleteIdsString));"
  var deleteImageStatement: OpaquePointer?
  if sqlite3_prepare_v2(db, deleteImageSql, -1, &deleteImageStatement, nil) == SQLITE_OK {
   if sqlite3_step(deleteImageStatement) != SQLITE_DONE {
    print("Error deleting image entries.")
   }
   sqlite3_finalize(deleteImageStatement)
  } else {
   let errmsg = String(cString: sqlite3_errmsg(db)!)
   print("Error preparing delete image entries: \(errmsg)")
  }
  
  // Update orderIndex of all the images after it
  let updateIndexSql = "UPDATE ImageOrder SET orderIndex = orderIndex - ? WHERE orderIndex > ?;"
  var updateIndexStatement: OpaquePointer?
  
  if sqlite3_prepare_v2(db, updateIndexSql, -1, &updateIndexStatement, nil) == SQLITE_OK {
   sqlite3_bind_int(updateIndexStatement, 1, Int32(deleteIds.count))
   sqlite3_bind_int(updateIndexStatement, 2, startIndexOrder)
   if sqlite3_step(updateIndexStatement) != SQLITE_DONE {
    print("Error updating orderIndexes after deletion.")
   }
   sqlite3_finalize(updateIndexStatement)
  } else {
   let errmsg = String(cString: sqlite3_errmsg(db)!)
   print("Error preparing update orderIndexes: \(errmsg)")
  }
  
  // Commit the transaction
  sqlite3_exec(db, "COMMIT;", nil, nil, nil)
  completion()
 }
}
