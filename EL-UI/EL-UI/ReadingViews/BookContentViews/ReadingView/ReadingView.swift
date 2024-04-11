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
  var body: some View {
    ZStack {
      switch readingMode {
      case .mixed:
        MixedReadingView(pageFlipMode: $pageFlipMode, viewContent: $viewContent, bookName: $bookName)
      case .singe:
        SingleReadingView()
      }
    }
  }
}

struct MixedReadingView: View {
  @Binding var pageFlipMode: PageFlipMode
  
  @Binding var viewContent: ViewContent
  @Binding var bookName: String
  
  var body: some View {
    switch pageFlipMode {
    case .scroll:
      ScrollShowView(bookName: $bookName, viewContent: $viewContent)
    case .page:
      Text("page view")
    }
  }
}

struct SingleReadingView: View {
  var body: some View {
    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
  }
}
