//
//  UserInfo.swift
//  EL
//
//  Created by WJR on 11/22/23.
//

import Foundation

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
  static let shared = UserSettings() // Singleton
  
  private let userDefaults = UserDefaults.standard
  
  // Define the storage keys
  private let isAgreedPolicyKey = "isAgreedPolicy"
  private let userEnglishLevelKey = "userEnglishLevel"
  
  private init() {
    // Load values from UserDefaults at initialization
    self.isAgreedPolicy = userDefaults.bool(forKey: isAgreedPolicyKey)
  }
  
  // Whether the policy was accepted (updates views)
  @Published var isAgreedPolicy: Bool {
    didSet {
      userDefaults.set(isAgreedPolicy, forKey: isAgreedPolicyKey)
    }
  }
  
  // The user's English level (no view binding needed)
  var userEnglishLevel: UserEnglishLevel? {
    get {
      if let data = userDefaults.data(forKey: userEnglishLevelKey) {
        return try? JSONDecoder().decode(UserEnglishLevel.self, from: data)
      }
      return nil
    }
    set {
      if let newValue = newValue {
        if let encoded = try? JSONEncoder().encode(newValue) {
          userDefaults.set(encoded, forKey: userEnglishLevelKey)
        }
      } else {
        userDefaults.removeObject(forKey: userEnglishLevelKey)
      }
    }
  }
}

// Definition of the user's English level
struct UserEnglishLevel: Codable {
  var learningSystem: LearningSystem
  var vocabularyLevel: VocabularyLevel
}

enum LearningSystem: String, Codable {
  case US
  case UK
}

enum VocabularyLevel: String, Codable {
  case beginner
  case intermediate
  case advanced
}
