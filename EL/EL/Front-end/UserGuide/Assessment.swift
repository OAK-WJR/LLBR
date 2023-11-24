//
//  VocabularyAssessment.swift
//  EL
//
//  Created by WJR on 11/9/23.
//

import Foundation
import SwiftUI

enum VocabularyLevel {
    case beginner // 0-2999 words
    case intermediate // 3000-5999 words
    case advanced // >6000 words
}

struct VocabularyAssessment: View {
  @Binding var currentStep: AssessmentStep
  @State var selectedLevel: VocabularyLevel? = nil

  var body: some View {
    VStack {
          
      Text("Select your vocabulary level")
        .font(.headline)

      Button("Beginner (0 - 2999 Words)") {
        selectedLevel = .beginner
      }
      .padding()
      
      Button("Intermediate (3000 - 5999 Words)") {
        selectedLevel = .intermediate
      }
      .padding()

      Button("Advanced (Over 6000 Words)") {
        selectedLevel = .advanced
      }
      .padding()

      if let level = selectedLevel {
        Text("You selected: \(textForLevel(level))")
          .font(.title)
      }
      
      HStack {
        Button("Last") {
          currentStep = .explanation
        }
      }
    }
  }

  private func textForLevel(_ level: VocabularyLevel) -> String {
    switch level {
    case .beginner:
      return "Beginner Level"
    case .intermediate:
      return "Intermediate Level"
    case .advanced:
      return "Advanced Level"
    }
  }
}
