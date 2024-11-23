//
//  ContentView.swift
//  EL-UI
//
//  Created by WJR on 1/22/24.
//
import SwiftUI

struct ContentView: View {
  @State var content: ViewContent = .reading(.bookContent(.readPage))
  @State var showMainContentView: Bool = false
  
  @State var bookName: String = "dairy"
  @State var chapterNow: Int = 0
  
  @State var showBookList: Bool = true
  
  var body: some View {
    if !UserSettings.shared.isAgreedPolicy {
      PrivacyConsentView()
    } else {
      if showMainContentView {
        MainNavigationView(content: $content, showMainNavigationView: $showMainContentView)
      } else {
        switch content {
        case .reading(let reading):
          switch reading {
          case .booksList:
            BooksStoreView(bookName: $bookName, content: $content, showBookList: $showBookList)
          case .bookContent(let bookContent):
            switch bookContent {
            case .readPage:
              ReadingView(bookName: $bookName, chapterNow: $chapterNow, viewContent: $content, showBookList: $showBookList)
            case .addPage:
              EmptyView()
            }
          case .bookEdit:
            ResourceEntryView(bookName: $bookName, mainContent: $content)
              .environmentObject(RE_ContentLoader())
          }
        case .learning:
          EmptyView()
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
