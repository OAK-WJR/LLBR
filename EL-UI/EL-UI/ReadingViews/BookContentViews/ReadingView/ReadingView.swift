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
  @Binding var viewContent: ViewContent
  
  @State var readingMode: ReadingMode = .mixed
  @State var pageFlipMode: PageFlipMode = .scroll
  
  @Binding var showBookList: Bool
  
  @State var showMenu: Bool = true
  
  var body: some View {
    ZStack {
      ZStack {
        switch readingMode {
        case .mixed:
          MixedReadingView(pageFlipMode: $pageFlipMode, viewContent: $viewContent, bookName: $bookName, showMenu: $showMenu)
        case .singe:
          SingleReadingView()
        }
      }
      
      VStack {
        if showMenu {
          Menu(viewContent: $viewContent, showBookList: $showBookList)
            .transition(.move(edge: .top))
        }
      }
    }
  }
}

struct MixedReadingView: View {
  @Binding var pageFlipMode: PageFlipMode
  
  @Binding var viewContent: ViewContent
  @Binding var bookName: String
  
  @Binding var showMenu: Bool
  
  var body: some View {
    switch pageFlipMode {
    case .scroll:
      ScrollShowView(bookName: $bookName, viewContent: $viewContent, showMenu: $showMenu)

    case .page:
      Text("page view")
    }
  }
}

struct Menu: View {
  @Binding var viewContent: ViewContent
  @Binding var showBookList: Bool
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
