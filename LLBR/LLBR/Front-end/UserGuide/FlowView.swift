//
//  FlowView.swift
//  EL
//
//  Created by WJR on 11/22/23.
//

import SwiftUI

enum AssessmentStep {
  case explanation
  case assessment
}

struct FlowView: View {
  @State private var currentStep: AssessmentStep = .explanation

  var body: some View {
    VStack {
      switch currentStep {
      case .explanation:
        ExplanationView(currentStep: $currentStep)
      case .assessment:
        VocabularyAssessment(currentStep: $currentStep)
      }
    }
  }
}
