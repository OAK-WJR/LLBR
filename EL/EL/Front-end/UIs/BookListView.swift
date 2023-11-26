//
//  BookView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

struct BookListView: View {
  @State var bookList = [String]()
  
  var body: some View {
    VStack(alignment: .center) {
      if bookList.count != 0 {
        List(bookList, id: \.self) { book in
          Text(book)
        }
        Spacer(minLength: 0)
      } else {
        LoadingView()
      }
    }
    .onAppear {
      BooksDatabase().getAllTablesName() { tables in
        print(tables)
        bookList = tables
        if bookList.contains("sqlite_sequence") {
          bookList.removeAll { $0 == "sqlite_sequence";}
        }
      }
    }
    .background(Color.gray.opacity(0.1))
  }
}
