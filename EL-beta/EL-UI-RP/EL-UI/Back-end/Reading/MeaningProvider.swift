//
//  MeaningProvider.swift
//  EL-UI
//
//  Created by WJR on 10/28/25.
//

import Foundation

// Minimal data model used only to parse chat/completions responses
public struct ChatResponse: Decodable {
  public struct Choice: Decodable {
    public struct Message: Decodable { public let content: String }
    public let message: Message
  }
  public let choices: [Choice]
}

public enum MeaningProvider {
  /// Business logic decides which model to use, how to write the messages, the temperature, etc.
  public static func fetchMeaning(word: String, context: String? = nil) async throws -> String {
    guard let ai = ToolBox.ai else {
      throw NSError(domain: "MeaningProvider", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "AIService not configured"])
    }

    // You can easily switch the model / how the messages are written here
    let body: [String: Any] = [
      "model": "gpt-4o-mini",       // ← The model is chosen in the Reading layer
      "temperature": 0.3,
      "messages": [
        ["role": "system", "content": "你是一个单词助手,结合上下文并给出文中指定的单词的最精准的意思和解释,回答只需要意思且不得超过10个字"],
        [
          "role": "user",
          "content":
            """
            解释英语单词: '\(word)' \
            \(context.map { "Context: \($0)" } ?? "") 到中文,回答只需要意思且不得超过10个字
            """
        ]
      ]
    ]

    let resp: ChatResponse = try await ai.sendRequest(
      endpoint: "chat/completions",
      body: body,
      decode: ChatResponse.self
    )
    return resp.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }
}
