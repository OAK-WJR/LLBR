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
  private let backgroundKey = "userBackground"
  
  private init() {
    self.isAgreedPolicy = userDefaults.bool(forKey: isAgreedPolicyKey)
    if let data = userDefaults.data(forKey: userEnglishLevelKey) {
      do {
        let decodedLevel = try JSONDecoder().decode(UserEnglishLevel.self, from: data)
        self.userEnglishLevel = decodedLevel
        print("UserEnglishLevel loaded successfully:", decodedLevel)
      } catch {
        print("Failed to decode UserEnglishLevel:", error)
        self.userEnglishLevel = nil
      }
    } else {
      self.userEnglishLevel = nil
      print("No UserEnglishLevel data found")
    }
    // Read background (defaults to an empty string)
    self.background = userDefaults.string(forKey: backgroundKey) ?? ""
  }
  
  // Whether the policy was accepted (updates views)
  @Published var isAgreedPolicy: Bool {
    didSet {
      //objectWillChange.send() // Notify SwiftUI to update
      userDefaults.set(isAgreedPolicy, forKey: isAgreedPolicyKey)
      print("isAgreedPolicy:", userDefaults.bool(forKey: isAgreedPolicyKey))
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
  @Published var background: String {
    didSet {
      userDefaults.set(background, forKey: backgroundKey)
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
  
  /// The matching vocabulary size
  var wordCount: Int {
    switch self {
    case .beginner:
      return 1000
    case .intermediate:
      return 3999
    case .advanced:
      return 5999
    }
  }
}

extension UserSettings {
  var backgroundSummary: String {
    guard let level = userEnglishLevel else { return "未设置" }
    print("英语学习经历:\(background)。\(level.learningSystem.rawValue)教材,词汇量大概\(level.vocabularyLevel.wordCount)")
    return "英语学习经历:\(background)。\(level.learningSystem.rawValue)教材,词汇量大概\(level.vocabularyLevel.wordCount)"
  }
}
