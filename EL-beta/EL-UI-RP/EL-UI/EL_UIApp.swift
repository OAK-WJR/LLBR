//
//  EL_UIApp.swift
//  EL-UI
//
//  Created by WJR on 1/22/24.
//

import SwiftUI

@main
struct EL_UIApp: App {
  init() {
    
    // ⚠️ Clear UserDefaults on every run
    if let bundleID = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: bundleID)
      UserDefaults.standard.synchronize()
    }

    // ⚠️ Clear the Documents folder on every run (e.g. caches, saved files)
    let fileManager = FileManager.default
    if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      if let files = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
        for file in files {
          try? fileManager.removeItem(at: file)
        }
      }
    }
    
    ToolBox.configure(apiKey: "###")  // Better not to hard-code this; move it to Keychain/.xcconfig
  }
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(UserSettings.shared)
    }
  }
}
