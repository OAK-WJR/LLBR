//
//  PrivacyConsentView.swift
//  EL-UI
//
//  Created by WJR on 10/12/24.
//

import SwiftUI

struct PrivacyConsentView: View {
  @ObservedObject var userSettings = UserSettings.shared
  var body: some View {
    VStack {
      Text("Privacy Policy")
        .font(.title)
        .padding()
      
      Text("We value your privacy. Please read our policy and agree to continue using the app.")
        .font(.body)
        .padding()
      
      Button(action: {
        // Open the external privacy policy link
        if let url = URL(string: "https://privacy.1ts.fun/product/240923uUxVFGe8SBicrg") {
          UIApplication.shared.open(url)
        }
      }) {
        Text("Read Privacy Policy")
          .padding()
          .background(Color.white)
          .foregroundColor(.black)
          .cornerRadius(10)
      }
      .padding()
      
      Button(action: {
        userSettings.isAgreedPolicy = true
        print(userSettings.isAgreedPolicy)
      }) {
        Text("Agree and Continue")
          .padding()
          .background(Color.white)
          .foregroundColor(.green)
          .cornerRadius(10)
      }
      .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground).opacity(0.9))
    .edgesIgnoringSafeArea(.all)
  }
}
