//
//  WordsShowingView.swift
//  EL-UI
//
//  Created by WJR on 4/8/24.
//

import SwiftUI
import UIKit
import CoreImage

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
  @State var sentenceTranslation: String?
  
  var body: some View {
    if selectedPageIndex >= 0 && selectedPageIndex < pdfContents.contents.count, // Check that selectedPageIndex is in range
       let textContent = pdfContents.contents[selectedPageIndex].textContent,
       let unknownWordsIndex = textContent.unknownWordsIndex { // Check that unknownWordsIndex exists
      VStack {
//        if showTranslation, let sentenceTranslation = sentenceTranslation {
//          TranslationView(sentence: sentenceTranslation, focusedWord: <#T##Binding<Word?>#>)
//        }
        Spacer()
        TabView(selection: $selectedWordIndex) {
          ForEach(unknownWordsIndex, id: \.self) { index in
            WordCardView(content: $pdfContents.contents[selectedPageIndex].textContent, index: index, bookName: bookName, pageIndex: selectedPageIndex, opacity: 0.75)
              .tag(index)
          }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 90)
      }
      .onAppear {
//        if let sentences = pdfContents.contents[selectedPageIndex].textContent?.sentences {
//          if let originalSentence = findSentence(in: sentences, for: selectedWordIndex) {
//            if let translation = translate(originalSentence) {
//              sentenceTranslation = translation
//            }
//          }
//        }
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
//  
//  func translate(_ text: String) -> String {
//    let tagger = NSLinguisticTagger(tagSchemes: [.translation], options: 0)
//    tagger.string = text
//    var translated = ""
//    
//    tagger.enumerateTags(in: NSRange(location: 0, length: text.utf16.count), unit: .sentence, scheme: .translation, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange, stop in
//      if let language = tag?.rawValue {
//        translated += language
//      } else {
//        translated += String(text[text.index(text.startIndex, offsetBy: tokenRange.lowerBound)..<text.index(text.startIndex, offsetBy: tokenRange.upperBound)])
//      }
//    }
//    return translated
//  }
}
