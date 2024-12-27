//
//  EL_UIApp.swift
//  EL-UI
//
//  Created by WJR on 1/22/24.
//

import SwiftUI

@main
struct EL_UIApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(UserSettings.shared)
    }
  }
}
