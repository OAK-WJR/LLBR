//
//  ToolBox.swift
//  EL-UI
//
//  Created by WJR on 10/28/25.
//

import Foundation

public enum ToolBox {
  public static var ai: AIService?

  /// Call this at app launch in AppDelegate/EL_UIApp
  public static func configure(apiKey: String) {
    ai = AIService(apiKey: apiKey)
  }
}
