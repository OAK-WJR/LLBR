//
//  BookView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

struct BookListView: View {
  @State var bookList = [BookInfo]()
  
  var body: some View {
    VStack(alignment: .center) {
      if bookList.count != 0 {
        List(0..<bookList.count, id: \.self) { i in
          Text(bookList[i].name)
        }
        Spacer(minLength: 0)
      } else {
        LoadingView()
      }
    }
    .onAppear {
      BooksDatabase().getBooksInfo { tables in
        print(tables)
        bookList = tables
      }
    }
    .background(Color.gray.opacity(0.1))
  }
}
