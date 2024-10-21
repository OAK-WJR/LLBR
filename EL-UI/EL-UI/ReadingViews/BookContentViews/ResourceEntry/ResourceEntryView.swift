//
//  ResourceEntryView.swift
//  EL-UI
//
//  Created by WJR on 4/10/24.
//

import SwiftUI

enum BookEditContent {
  case typeSelection
  case entry
  case edit
}

struct ResourceEntryView: View {
  @Binding var bookName: String
  @Binding var mainContent: ViewContent
  @State var viewContent: BookEditContent = .entry

  var body: some View {
    ZStack {
      CustomCameraView(mainContent: $mainContent, viewContent: $viewContent)
      
      VStack {
        if viewContent == .edit {
          ResourceEditView(bookName: $bookName, mainContent: $mainContent, viewContent: $viewContent)
            .transition(.move(edge: .trailing))
        }
      }
    }
  }
}
