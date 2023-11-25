//
//  BookView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

//Launch button
struct BookListButtonView: View {
  @Binding var bookName: String
  @Binding var showingBooksList: Bool
  var body: some View {
    VStack {
      Button(action: {
        showingBooksList.toggle()
      }) {
        HStack() {
          Image(systemName: "list.bullet")
          Text(bookName.uppercased())
          Spacer(minLength: 0)
        }
      }
    }
  }
}

//List
struct BookListView: View {
  @State var bookList = [String]()
  @State private var isRotating = false
  @State private var isSwinging = false
  
  var body: some View {
    VStack(alignment: .center) {
      if bookList == [String]() {
        Spacer(minLength: 0)
        Image(systemName: "circle.dashed")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .rotationEffect(.degrees(isRotating ? 360 : 0))
          .rotation3DEffect(.degrees(isSwinging ? 20 : -20), axis: (x: 0, y: 2, z: 1))
          .onAppear {
            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
              isRotating = true
            }
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
              isSwinging = true
            }
          }
        Spacer(minLength: 0)
      } else {
        List(bookList, id: \.self) { book in
          Text(book)
        }
        Spacer(minLength: 0)
      }
    }
    .onAppear {
      BooksDatabase().allTables() { tables in
        bookList = tables
        if bookList.contains("sqlite_sequence") {
          bookList.removeAll { $0 == "sqlite_sequence";}
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
  }
}
