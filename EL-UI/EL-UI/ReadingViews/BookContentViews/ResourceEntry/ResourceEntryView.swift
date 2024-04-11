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
  @State var viewContent: BookEditContent = .entry
  var body: some View {
    
    switch viewContent {
    case .typeSelection:
      EmptyView()
    case .entry:
      CustomCameraView(viewContent: $viewContent)
        .transition(.asymmetric(
          insertion: .move(edge: .trailing),
          removal: .move(edge: .leading)
        ))
    case .edit:
      ResourceEditView()
    }
    
    
  }
}
