//
//  LearningResultsDisplayView.swift
//  EL-UI
//
//  Created by WJR on 1/24/24.
//

import SwiftUI

struct LearningResultsDisplayView: View {
  @Binding var showMainNavigationView: Bool
    var body: some View {
      VStack {
        HStack {
          Button(action: {
            showMainNavigationView = true
          }) {
            Image(systemName: "globe.badge.chevron.backward")
              .font(.headline)
              .foregroundStyle(.white)
              .padding(.horizontal)
          }
          Spacer()
        }
        Spacer()
        Text("Coming soon")
          .font(.title)
          .foregroundStyle(.white)
        Spacer()
      }
    }
}
