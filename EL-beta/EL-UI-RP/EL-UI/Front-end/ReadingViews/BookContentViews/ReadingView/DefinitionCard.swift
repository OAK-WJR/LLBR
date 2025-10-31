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
  @Binding var content: RPInfoContent?
  var sentenceTranslation: String
  var index: Int

  var bookName: String
  var pageIndex: Int

  var opacity: CGFloat

  @State private var aiText = ""
  @State private var aiLoading = false
  @State private var aiError: String?

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      if let word = content?.texts?[index],
         let learningWordsIndex = content?.learningWordsIndex {

        let showWord = content?.definitions?[word.texts.lowercased()]?.word ?? word.texts

        VStack {
          // Pronunciation button + headword
          Button(action: {
            let manager = TextToSpeechManager()
            manager.speak(text: showWord)
          }) {
            Text(showWord)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.blue)
              .lineLimit(1)
          }
          .onAppear {
            // Keep your original auto-pronunciation logic
            let manager = TextToSpeechManager()
            manager.speak(text: showWord)
          }
          
          ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 5) {
              ForEach(content!.definitionForWord(at: index), id: \.self) { definition in
                Text(definition)
                  .font(.system(size: 10))
                  .foregroundColor(.secondary)
              }
            }
          }
        }

        // Adaptive divider (no fixed white)
        Divider()
          .background(Color.secondary.opacity(0.4))

        // Right side: AI first, then the dictionary
      
        // ===== AI meaning (on top) =====
        VStack(alignment: .leading) {
          Text("AI 释义")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

          if aiLoading {
            HStack(spacing: 8) {
              ProgressView().controlSize(.small)
              Text("正在生成…").foregroundStyle(.secondary)
            }
          } else if let e = aiError {
            Text(e).font(.footnote).foregroundStyle(.secondary)
          } else if !aiText.isEmpty {
            Text(aiText)
              .font(.callout)
              .foregroundStyle(.primary)
              .fixedSize(horizontal: false, vertical: true)
          } else {
            Text("（暂无内容）").font(.footnote).foregroundStyle(.secondary)
          }
        }
        .padding(8)
        //.background(.ultraThinMaterial) // Dynamic material background; does not wash out in light mode
        //.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

        Spacer(minLength: 0)

        // Study-list (star) button (keep your logic)
        let learning = learningWordsIndex.contains(index)
        Button(action: {
          if learning {
            if let first = content?.learningWordsIndex?.firstIndex(of: index) {
              content?.learningWordsIndex?.remove(at: first)
            }
            DispatchQueue.global(qos: .userInitiated).async {
              UnknowWordsDatabase.shared.remove(words: [word.texts.lowercased()])
            }
          } else {
            content?.learningWordsIndex?.append(index)
            DispatchQueue.global(qos: .userInitiated).async {
              UnknowWordsDatabase.shared.add(
                words: [word.texts.lowercased()],
                bookIndex: bookName,
                pageIndex: pageIndex
              )
            }
          }
        }) {
          Image(systemName: learning ? "star.fill" : "star")
        }
        .buttonStyle(.plain)
      }
    }
    .padding(10)
    .background {
      // Previously a fixed black background + forced dark mode; now "system semantic colors + material"
      RoundedRectangle(cornerRadius: 15, style: .continuous)
        .fill(Color(.systemBackground).opacity(max(0.2, Double(opacity))))
        .overlay(
          RoundedRectangle(cornerRadius: 15, style: .continuous)
            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }
    .frame(width: 300)            // No fixed height anymore, so content is not cut off
    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    // .preferredColorScheme(.dark)  ← Removed forced dark mode; let the system adapt automatically
    .task(id: taskId) { await loadAI() }  // Load when the card appears or the word changes
  }

  // Return a task id based on the current card's word, so .task runs again automatically when the word changes
  private var taskId: String {
    guard let word = content?.texts?[index].texts else { return "unknown-\(index)" }
    return word.lowercased()
  }

  // Call the Reading layer's MeaningProvider directly from the view (no ViewModel)
  private func loadAI() async {
    guard
      let w = content?.texts?[index].texts,
      !w.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return }

    aiLoading = true; aiError = nil; aiText = ""
    do {
      aiText = try await MeaningProvider.fetchMeaning(word: w, context: sentenceTranslation)
    } catch {
      aiError = "AI 释义失败：\(error.localizedDescription)"
    }
    aiLoading = false
  }
}

// Get the dictionary meaning safely, avoiding a crash from force-unwrapping
extension RPInfoContent {
  func definitionForWord(at index: Int) -> [String] {
    guard
      let word = texts?[index],
      let defs = definitions?[word.texts.lowercased()]
    else { return [] }
    return defs.definitions.values.flatMap { $0 }
  }
}


/*
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
   @Binding var content: RPInfoContent?
   var index: Int
   
   var bookName: String
   var pageIndex: Int
   
   var opacity: CGFloat
   
   var body: some View {
     HStack(alignment: .top) {
       if let word = content?.texts?[index],
          let learningWordsIndex = content?.learningWordsIndex {
         
         let showWord = content?.definitions?[word.texts.lowercased()]?.word ?? word.texts

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
             ForEach(content!.definitionForWord(at: index), id: \.self) { definition in
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
             content?.learningWordsIndex?.remove(at: (content?.learningWordsIndex?.firstIndex(of: index))!)
             DispatchQueue.global(qos: .userInitiated).async {
               UnknowWordsDatabase().remove(words: [word.texts.lowercased()])
             }
           } else {
             content?.learningWordsIndex?.append(index)
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
     .preferredColorScheme(.dark)
   }
 }

 extension RPInfoContent {
   func definitionForWord(at index: Int) -> [String] {
     guard let word = texts?[index],
           let wordData = definitions![word.texts.lowercased()] else {
       return []
     }
     
     return wordData.definitions.values.flatMap { $0 }
   }
 }

 */
