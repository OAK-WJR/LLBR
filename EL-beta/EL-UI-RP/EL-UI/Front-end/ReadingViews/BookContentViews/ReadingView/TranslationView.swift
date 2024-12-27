//
//  TranslationView.swift
//  EL-UI
//
//  Created by WJR on 12/26/24.
//

import SwiftUI

struct TranslationView: View {
  var sentence: String
  @Binding var focusedWord: Word?
  
  var body: some View {
    // Use a ZStack to layer the background and the text
    ZStack {
      // Semi-transparent background
      RoundedRectangle(cornerRadius: 10) // Rounded rectangle background
        .fill(Color.black.opacity(0.3)) // Black semi-transparent background, opacity 0.3
        .frame(maxWidth: .infinity) // Fill the width of the parent view
        .padding(.horizontal) // Add some padding on the left and right
      
      // Translated text
      Text(sentence)
        .font(.system(size: 20, weight: .bold, design: .rounded)) // Set the font size, weight and rounded design
        .foregroundColor(.white) // White text, so it stays readable on a dark background
        .padding() // Add padding around the text
        .multilineTextAlignment(.center) // Center multi-line text
        .lineLimit(nil) // Allow the text to wrap, with no line limit
    }
  }
}
