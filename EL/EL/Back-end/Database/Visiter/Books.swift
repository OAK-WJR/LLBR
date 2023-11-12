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
    // Open the database connection here
    // e.g. sqlite3_open("path_to_database", &db)
  }
  
  // MARK: - Top-level functions - General operations
  func addOperation(_ elementType: ElementType, _ data: Any, at index: Int, in tableName: String) {
    switch elementType {
    case .content:
      addOriginal(at: index, original: data, to: tableName)
    case .crop:
      addCrop(at: index, crop: data, to: tableName)
    case .original:
      addContent(at: index, content: data as! PageContent, to: tableName)
    }
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
        Page INTEGER PRIMARY KEY,
        Type TEXT,
        Original BLOB,
        Crop BLOB,
        Words TEXT,
        Positions BLOB
      );
      """
      // Run the SQL to create the table here
  }

  // 1.2 Rename a table
  func changeTableName(from oldName: String, to newName: String) {
      // Execute the SQL statement to rename a table
      let renameTableString = "ALTER TABLE \(oldName) RENAME TO \(newName);"
      // Run the SQL to rename the table here
  }

  // 1.3 Delete a table
  func deleteTable(named tableName: String) {
      // Execute the SQL statement to delete a table
      let deleteTableString = "DROP TABLE IF EXISTS \(tableName);"
      // Run the SQL to delete the table here
  }

  // MARK: - Helper functions - Original data operations

  // 2.1 Add Type and Original content
  public func addOriginal(at index: Int, original: Any, to tableName: String) {
    //Store Type according to the type of original
    // Process the Original data according to Type (e.g. convert to Blob)
    // Run the SQL to insert content here
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
  public func addCrop(at index: Int, crop: Any, to tableName: String) {
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

  // MARK: - Helper functions - Words and Positions operations

  // 4.1 Add Words and Positions content
  public func addContent(at index: Int, content: PageContent, to tableName: String) {
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
  public func getContent(at indexu: Int, from tableName: String) -> (words: [[[String]]]?, positions: Any?) {
      // Run the SQL to query words and positions content here and parse it by Type
      // Return the parsed words and positions
      return (nil, nil)
  }

  // Close the database connection
  deinit {
      // Close the database connection here
      // e.g. sqlite3_close(db)
  }
}
