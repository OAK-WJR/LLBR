//
//  ContentView.swift
//  EL-UI
//
//  Created by WJR on 1/22/24.
//
import SwiftUI

struct ContentView: View {
  @State var content: ViewContent = .reading(.bookEdit)
  @State var showMainNavigationView: Bool = true
  
  @State var bookName: String = "dairy"
  
  @State var showBookList: Bool = false
  
  @State var showPrivacyConsent: Bool = !UserDefaults.standard.bool(forKey: "PrivacyPolicyAgreed")
  
  var body: some View {
    // If the privacy policy has not been accepted yet, show the privacy policy view first
    if showPrivacyConsent {
      PrivacyConsentView(showPrivacyConsent: $showPrivacyConsent)
    } else {
      if showMainNavigationView {
        MainNavigationView(content: $content, showMainNavigationView: $showMainNavigationView)
      } else {
        switch content {
        case .reading(let reading):
          switch reading {
          case .booksList:
            BooksStoreView(bookName: $bookName, showMainNavigationView: $showMainNavigationView, content: $content, showBookList: $showBookList)
          case .bookContent(let bookContent):
            switch bookContent {
            case .readPage:
              ReadingView(bookName: $bookName, viewContent: $content, showBookList: $showBookList)
            case .addPage:
              EmptyView()
            }
          case .bookEdit:
            ResourceEntryView(bookName: $bookName, mainContent: $content)
              .environmentObject(RE_ContentLoader())
          }
        case .learning:
          LearningResultsDisplayView(showMainNavigationView: $showMainNavigationView)
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
