//
//  ContentView.swift
//  EL-UI
//
//  Created by WJR on 1/22/24.
//
import SwiftUI

struct ContentView: View {
  @State var content: ViewContent = .reading(.bookEdit)
  @State var showMainContentView: Bool = false
  
  @State var bookName: String = "dairy"
  
  var body: some View {
    if showMainContentView {
      MainNavigationView(content: $content, showMainNavigationView: $showMainContentView)
    } else {
      switch content {
      case .reading(let reading):
        switch reading {
        case .booksList:
          BooksStoreView(bookName: $bookName, content: $content)
        case .bookContent(let bookContent):
          switch bookContent {
          case .readPage:
            ReadingView(bookName: $bookName, viewContent: $content)
          case .addPage:
            EmptyView()
          }
        case .bookEdit:
          ResourceEntryView()
        }
      case .learning:
        EmptyView()
      }
    }
  }
}

#Preview {
  ContentView()
}
