//
//  WordsShowingView.swift
//  EL-UI
//
//  Created by WJR on 4/8/24.
//

import SwiftUI
import UIKit
import CoreImage
import MLKitTranslate

/*
struct WordsShowingView: View {
  var bookName: String
  var selectedPageId: Int?
  @Binding var selectedWordIndex: Int
  
  @ObservedObject var CL: RP_ContentLoader
  @ObservedObject var VO: RP_ViewObserver
  
  var body: some View {
    if let selectedPageIndex = CL.contents.firstIndex(where: {$0.id == selectedPageId ?? VO.appearedPageIds.first}),
       let textContent = CL.contents[selectedPageIndex].textContent {
      VStack {
        Spacer()
        TabView(selection: $selectedWordIndex) {
          ForEach(textContent.unknownWordsIndex!, id: \.self) { index in
            WordCardView(content: $CL.contents[selectedPageIndex], index: index, bookName: bookName, pageIndex: selectedPageIndex, opacity: 0.75)
              .tag(index)
          }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 90)
      }
    }
  }
}
*/

struct WordsShowingView: View {
  @Binding var showTranslation: Bool
  var bookName: String
  @Binding var selectedPageIndex: Int
  @Binding var selectedWordIndex: Int
  @Binding var pdfContents: PDFContent
  @State var sentenceTranslation: String = ""
  
  var body: some View {
    if selectedPageIndex >= 0 && selectedPageIndex < pdfContents.contents.count, // Check that selectedPageIndex is in range
       let textContent = pdfContents.contents[selectedPageIndex].textContent,
       let unknownWordsIndex = textContent.unknownWordsIndex { // Check that unknownWordsIndex exists
      VStack {
        if showTranslation, sentenceTranslation != "" {
          TranslationView(sentence: $sentenceTranslation)
            .frame(width: 300, height: 90)
        }
        Spacer()
        TabView(selection: $selectedWordIndex) {
          ForEach(unknownWordsIndex, id: \.self) { index in
            WordCardView(content: $pdfContents.contents[selectedPageIndex].textContent, sentenceTranslation: sentenceTranslation, index: index, bookName: bookName, pageIndex: selectedPageIndex, opacity: 0.75)
              .tag(index)
          }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 90)
      }
      .onChange(of: selectedWordIndex) {
        if let sentences = pdfContents.contents[selectedPageIndex].textContent?.sentences {
          if let originalSentence = findSentence(in: sentences, for: selectedWordIndex) {
            /*
            translate(originalSentence) { translatedText in
              if let translatedText = translatedText {
                sentenceTranslation = translatedText
                print("Translated Text: \(translatedText)")
              } else {
                print("Translation failed.")
              }
            }
             */
          }
        }
      }
    }
  }
}

extension WordsShowingView {
  func findSentence(in ranges: [Range<Int>: String], for index: Int) -> String? {
    return ranges.first { range, _ in
      range.contains(index)
    }?.value
  }
  
  func translate(_ text: String, completion: @escaping (String?) -> Void) {
    // Configure the translator (English to Chinese)
    let options = TranslatorOptions(sourceLanguage: .english, targetLanguage: .chinese)
    let translator = Translator.translator(options: options)
    
    // Make sure the translation model is downloaded
    let conditions = ModelDownloadConditions(
      allowsCellularAccess: false,
      allowsBackgroundDownloading: true
    )
    translator.downloadModelIfNeeded(with: conditions) { error in
      guard error == nil else {
        print("Error downloading model: \(error?.localizedDescription ?? "unknown error")")
        completion(nil)
        return
      }
      
      // Translate
      translator.translate(text) { translatedText, error in
        guard error == nil, let translatedText = translatedText else {
          print("Error during translation: \(error?.localizedDescription ?? "unknown error")")
          completion(nil)
          return
        }
        completion(translatedText)
      }
    }
  }
}
