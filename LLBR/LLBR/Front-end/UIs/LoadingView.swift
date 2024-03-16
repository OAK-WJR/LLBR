//
//  LoadingView.swift
//  EL
//
//  Created by WJR on 11/25/23.
//

import SwiftUI

struct LoadingView: View {
  @State private var isRotating = false
  @State private var isSwinging = false
  var body: some View {
    VStack {
      Spacer(minLength: 0)
      Image(systemName: "circle.dashed")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .padding(50)
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
    }
  }
}
