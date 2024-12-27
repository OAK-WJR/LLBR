//
//  UserInfo.swift
//  EL
//
//  Created by WJR on 11/22/23.
//

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
  static let shared = UserSettings() // Singleton
  
  private let userDefaults = UserDefaults.standard
  
  // Define the storage keys
  private let isAgreedPolicyKey = "isAgreedPolicy"
  private let userEnglishLevelKey = "userEnglishLevel"
  
  private init() {
      self.isAgreedPolicy = userDefaults.bool(forKey: isAgreedPolicyKey)
      if let data = userDefaults.data(forKey: userEnglishLevelKey) {
          do {
              self.userEnglishLevel = try JSONDecoder().decode(UserEnglishLevel.self, from: data)
              print("UserEnglishLevel loaded successfully:", self.userEnglishLevel ?? "nil")
          } catch {
              print("Failed to decode UserEnglishLevel:", error)
              self.userEnglishLevel = nil
          }
      } else {
          self.userEnglishLevel = nil
          print("No UserEnglishLevel data found")
      }
  }
  
  // Whether the policy was accepted (updates views)
  @Published var isAgreedPolicy: Bool {
    didSet {
      objectWillChange.send() // Notify SwiftUI to update
      userDefaults.set(isAgreedPolicy, forKey: isAgreedPolicyKey)
      print("isAgreedPolicy:", userDefaults.bool(forKey: "isAgreedPolicy"))
    }
  }
  
  // The user's English level (updates views)
  @Published var userEnglishLevel: UserEnglishLevel? {
    didSet {
      if let newValue = userEnglishLevel {
        do {
          let encoded = try JSONEncoder().encode(newValue)
          userDefaults.set(encoded, forKey: userEnglishLevelKey)
          print("UserEnglishLevel saved successfully")
        } catch {
          print("Failed to encode UserEnglishLevel:", error)
        }
      } else {
        userDefaults.removeObject(forKey: userEnglishLevelKey)
        print("UserEnglishLevel removed")
      }
    }
  }
}

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
