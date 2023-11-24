//
//  UserGuide.swift
//  EL
//
//  Created by WJR on 11/22/23.
//

import SwiftUI

struct ExplanationView: View {
  @State private var selectedCountry: String = "USA"
  @Binding var currentStep: AssessmentStep
  let countries = ["China", "UK", "Canada", "Australia"]

    var body: some View {
        VStack {
          Text(explanationText(for: selectedCountry))
            .padding()

          Picker("Select your country", selection: $selectedCountry) {
            ForEach(countries, id: \.self) {
              Text($0)
            }
          }
          .pickerStyle(MenuPickerStyle())
          
          HStack {
            Button("Next") {
              currentStep = .assessment
            }
          }
        }
        .navigationBarTitle("Reading Assistant")
        .navigationBarItems(trailing: countryPicker)
    }

    private func explanationText(for country: String) -> String {
        switch country {
        case "China":
          return "This is a reading assistant to help English learners in the USA to read and learn English words."
        case "UK":
          return "This is a reading assistant to help English learners in the UK to read and learn English words."
        // ...explanations for other countries
        default:
          return "Select your country for a customized explanation."
        }
    }

    private var countryPicker: some View {
      Picker("Country", selection: $selectedCountry) {
        ForEach(countries, id: \.self) {
          Text($0)
        }
      }
      .pickerStyle(MenuPickerStyle())
    }
}
