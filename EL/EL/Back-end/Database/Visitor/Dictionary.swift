//
//  Dictionary.swift
//  EL
//
//  Created by WJR on 11/22/23.
//

import Foundation

class DictionaryDatabase {
  // Database connection pointer
  var db: OpaquePointer?
  
  // Initialize the database connection
  init() {
    // Open the database connection here
    // e.g. sqlite3_open("path_to_database", &db)
  }
  
  //MARK: - Main function - Filter words
  
  func definition(_ words: [Word?]) -> [String?] {
    //splitForm = group the words with firstLetterClassification -> ([String:[String]], [String:[[Int]]])
    /*Ex: [Word(texts: "apple", pos: .noun),
           Word(texts: "banana", pos: .noun),
           Word(texts: "cat", pos: .noun),
           Word(texts: "act", pos: .noun),
           Word(texts: "camera", pos: .noun),
           Word(texts: "apple", pos: .noun)]
     */
    
    /*  ->["a":["apple", "act"],
           "b":["banana"],
           "c":["cat", "camera"]
     */
    //  ->["a":[[0, 5], [3]], "b":[[1]], "c":[[2], [4]]
    
    
    //definitions = look up the definitions of the words in splitForm[0] in the database, using "" when there is none
    /*Ex: ["a":["apple", "act"],
           "b":["banana"],
           "c":["cat", "camera"]
     */
    /*Database: ["apple":"n. apple",
              "act":"n. behavior",
              "banana":"n. banana",
              "cat":"n. cat"]
     */

    //  ->["a":["n. apple", "n. behavior"], "b":["n. banana"], "c":["n. cat", ""]]

    
    //formated = use splitForm[1] to put filtered back into the original order
    //Ex: filtered = ["a":["n. apple", "n. behavior"], "b":["n. banana"], "c":["n. cat", ""]]
    //    splitForm[1]] = ["a":[[0, 5], [3]], "b":[[1]], "c":[[2], [4]]
    
    //  ->["n. apple", "n. banana", "n. cat", "n. behavior", "", "n. apple"]
    
    
    //return formated
    return [nil]
  }
  
  // Close the database connection
  deinit {
    // Close the database connection here
    // e.g. sqlite3_close(db)
  }
}
