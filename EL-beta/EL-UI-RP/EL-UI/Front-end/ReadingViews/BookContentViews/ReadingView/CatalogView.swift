//
//  CatalogView.swift
//  EL-UI
//
//  Created by WJR on 9/27/24.
//

import SwiftUI

struct CatalogView: View {
  @Binding var chapters: [Int]
  @Binding var showCatalog: Bool
  @Binding var bookName: String
  @Binding var chapterNow: Int
  var body: some View {
    List(chapters.indices, id: \.self) { i in
      HStack {
        Text("Chapter \(chapters[i])")
          .bold()
          .foregroundStyle(chapterNow == chapters[i] ? Color.black : Color.black.opacity(0.8))
        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture {
        chapterNow = chapters[i]
        withAnimation {
          showCatalog = false
        }
      }
    }
  }
}
