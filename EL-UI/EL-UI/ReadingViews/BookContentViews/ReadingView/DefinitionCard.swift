//
//  DefinitionCard.swift
//  EL-UI
//
//  Created by WJR on 3/28/24.
//

import SwiftUI
import UIKit
import CoreImage
import Combine

struct WordCardView: View {
  @Binding var content: RPContent
  var index: Int
  
  var bookName: String
  var pageIndex: Int
  
  var opacity: CGFloat
  
  var body: some View {
    HStack(alignment: .top) {
      if let word = content.textContent?.texts?[index],
         let learningWordsIndex = content.textContent?.learningWordsIndex {
        
        let showWord = content.textContent?.definitions?[word.texts.lowercased()]?.word ?? word.texts

        Button(action: {
          let manager = TextToSpeechManager()
          manager.speak(text: showWord)
        }) {
          Text(showWord)
            .font(.system(size: 15))
            .fontWeight(.bold)
            .foregroundColor(Color.blue)
        }
        .onAppear {
          let manager = TextToSpeechManager()
          manager.speak(text: showWord)
        }
        
        Divider()
          .background(.white)
          .shadow(color: .white.opacity(0.5), radius: 5, x: 0, y: 2)
        
        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: 5) {
            ForEach(content.definitionForWord(at: index), id: \.self) { definition in
              Text(definition)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }
          }
        }
        
        Spacer(minLength: 0)
        
        let learning = learningWordsIndex.contains(index)
        Button(action: {
          print(learning)
          print(index)
          if learning {
            content.textContent?.learningWordsIndex?.remove(at: (content.textContent?.learningWordsIndex?.firstIndex(of: index))!)
            DispatchQueue.global(qos: .userInitiated).async {
              UnknowWordsDatabase().remove(words: [word.texts.lowercased()])
            }
          } else {
            content.textContent?.learningWordsIndex?.append(index)
            DispatchQueue.global(qos: .userInitiated).async {
              print(word.texts)
              UnknowWordsDatabase().add(words: [word.texts.lowercased()], bookIndex: bookName, pageIndex: pageIndex)
            }
          }
        }) {
          Image(systemName: learning ? "star.fill" : "star")
        }
      }
    }
    .padding()
    .background {
      Rectangle()
        .fill(Color.black.opacity(opacity))
        .cornerRadius(15)
        .overlay(
          RoundedRectangle(cornerRadius: 15)
            .stroke(Color.black, lineWidth: 1)
        )
    }
    .frame(width: 300, height: 90)
    .shadow(color: .white.opacity(0.5), radius: 5, x: 0, y: 0.5)
    
  }
}

extension RPContent {
  func definitionForWord(at index: Int) -> [String] {
    guard let word = textContent?.texts?[index],
          let wordData = textContent?.definitions![word.texts.lowercased()] else {
      return []
    }
    
    return wordData.definitions.values.flatMap { $0 }
  }
}
