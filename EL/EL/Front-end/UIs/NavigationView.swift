//
//  NavigationView.swift
//  EL
//
//  Created by WJR on 11/25/23.
//

import SwiftUI

enum SideContentTag {
  case bookList
  case none
}

struct NavigationView: View {
  @State var screen = UIScreen.main.bounds.size
  @Binding var bookName: String
  @Binding var index: Int
  @Binding var ids: [Int]
  @Binding var sideContent: SideContentTag
  @Binding var mainContent: MainContentTag
  var body: some View {
    HStack {
      Button(action: {
        withAnimation {
          if sideContent == .none{
            sideContent = .bookList
          } else {
            sideContent = .none
          }
        }
      }) {
        HStack() {
          Text(" ")
          Image(systemName: "list.bullet")
          Text(bookName.uppercased())
        }
        .foregroundColor(.white)
        .font(Font.headline.weight(.bold))
      }
      Button(action: {
        if mainContent == .camera {
          mainContent = .photos
        } else {
          mainContent = .camera
        }
        
      }) {
        Text(String(ids.count))
          .frame(maxWidth: .infinity)
          .foregroundColor(.white)
          .font(Font.headline.weight(.bold))
      }
      .onAppear {
        DispatchQueue.global(qos: .userInitiated).async {
          ids = BooksDatabase().getAllIds(from: bookName)
        }
      }
    }
  }
}
