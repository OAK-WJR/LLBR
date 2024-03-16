//
//  GeneralTools.swift
//  EL
//
//  Created by WJR on 11/13/23.
//

import Foundation

func firstLetterClassification(_ words: [Word]) -> ([String?:[Word?]], [String?:[[Int?]]]) {
  //Group the texts in the words array by first letter
  
  //Output the grouped lists and their original indexes
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
  return ([nil:[nil]], [nil:[[nil]]])
}
