//
//  ReadingView.swift
//  EL-UI
//
//  Created by WJR on 2/8/24.
//

import SwiftUI

import CoreImage

struct ReadingView: View {
  @Binding var bookName: String
  @Binding var chapterNow: Int
  @Binding var viewContent: ViewContent
  
  @State var readingMode: ReadingMode = .mixed
  @State var pageFlipMode: PageFlipMode = .scroll
  
  @Binding var showBookList: Bool
  
  @State var showMenu: Bool = false
  @State var showCatalog: Bool = false
  
  @State var chapters: [Int] = []
  
  var body: some View {
    ZStack {
      switch readingMode {
      case .mixed:
        MixedReadingView(pageFlipMode: $pageFlipMode, viewContent: $viewContent, bookName: $bookName, chapterNow: $chapterNow, showMenu: $showMenu)
      case .singe:
        SingleReadingView()
      }
      
      VStack {
        if showMenu {
          Menu(viewContent: $viewContent, showBookList: $showBookList, showCatalog: $showCatalog)
            .transition(.move(edge: .top))
        }
      }
      
      VStack {
        if showCatalog {
          CatalogView(chapters: $chapters, showCatalog: $showCatalog, bookName: $bookName, chapterNow: $chapterNow)
            .transition(.move(edge: .trailing))
        }
      }
    }
    .onAppear {
      DispatchQueue.global(qos: .userInitiated).async {
        chapters = BooksDatabase().getAllChapterIds(from: bookName).map{$0.0}
      }
    }
  }
}

struct MixedReadingView: View {
  @Binding var pageFlipMode: PageFlipMode
  
  @Binding var viewContent: ViewContent
  @Binding var bookName: String
  @Binding var chapterNow: Int
  
  @Binding var showMenu: Bool
  
  var body: some View {
    switch pageFlipMode {
    case .scroll:
      ScrollShowView(showMenu: $showMenu, bookName: $bookName, chapterNow: $chapterNow)

    case .page:
      Text("page view")
    }
  }
}

struct Menu: View {
  @Binding var viewContent: ViewContent
  @Binding var showBookList: Bool
  @Binding var showCatalog: Bool
  var body: some View {
    VStack {
      HStack {
        Button(action: {
          showBookList = false
          viewContent = .reading(.booksList)
        }) {
          Image(systemName: "chevron.backward")
            .foregroundStyle(.white)
            .padding()
        }
        
        Spacer()
        
        Button(action: {
          withAnimation {
            showCatalog = true
          }
        }) {
          Image(systemName: "list.bullet")
            .foregroundStyle(.white)
            .padding()
        }
        
        Button(action: {
          viewContent = .reading(.bookEdit)
        }) {
          Image(systemName: "plus")
            .foregroundStyle(.white)
            .padding()
        }
        
      }
      .background(Color.black.opacity(0.8).ignoresSafeArea())
      
      Spacer()
    }
  }
}

struct SingleReadingView: View {
  var body: some View {
    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
  }
}
