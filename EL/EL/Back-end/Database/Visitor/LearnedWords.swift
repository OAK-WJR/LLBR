//
//  LearnedWords.swift
//  EL
//
//  Created by WJR on 11/13/23.
//

import Foundation

class LearedWordsDatabase {
  // Database connection pointer
  var db: OpaquePointer?
  
  // Initialize the database connection
  init() {
    // Open the database connection here
    // e.g. sqlite3_open("path_to_database", &db)
  }
  
  // MARK: - Main function - Add words
  
  func add(_ words: [Word]) {
    //splitForm = group the words with firstLetterClassification -> ([String:[String]], [String:[[Int]]])
    //Use splitForm[0] to add each new word to its own database
  }
  // MARK: - Main function - Remove words
  
  func remove(_ words: [Word]) {
    //splitForm = group the words with firstLetterClassification -> ([String:[String]], [String:[[Int]]])
    //Use splitForm[0] to delete the matching words from the database
  }
  //MARK: - Main function - Filter words
  
  func filter(_ words: [Word?]) -> [Word?] {
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
    return [nil]
  }
  
  // Close the database connection
  deinit {
    // Close the database connection here
    // e.g. sqlite3_close(db)
  }
}
