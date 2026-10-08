//
//  PossibleAIFilter.swift
//  EL-UI
//
//  Created by WJR on 10/29/25.
//

// PossibleAIFilter.swift

import Foundation

private struct AIPossibleKnownResponse: Decodable {
  let known_lines: [Int]
}

final class PossibleAIFilter {
  let background: String
  init(background: String) { self.background = background }

  // Only handle unknownWordsIndex; deduplicate these words before sending them to the AI; on a match, remove every original index of that word
  func possibleAIFilter(words: [Word], unknownWordsIndex: [Int]) async -> [Int] {
    // 1) Take the unknown words and normalize them (lowercase + strip leading/trailing punctuation)
    func norm(_ s: String) -> String {
      s.lowercased().trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
    }

    // originalIdx -> token
    var tokenForOriginal = [Int: String]()
    for idx in unknownWordsIndex where idx >= 0 && idx < words.count {
      tokenForOriginal[idx] = norm(words[idx].texts)
    }

    // 2) Deduplicate: uniqueTokens (line numbers use its indexes), and build the mapping uniqueLine -> [originalIdx...]
    var uniqueTokens: [String] = []
    var tokenToUniqueLine = [String: Int]()
    var uniqueLineToOriginals = [[Int]]()

    for (origIdx, tok) in tokenForOriginal {
      if let line = tokenToUniqueLine[tok] {
        uniqueLineToOriginals[line].append(origIdx)
      } else {
        let newLine = uniqueTokens.count
        uniqueTokens.append(tok)
        tokenToUniqueLine[tok] = newLine
        uniqueLineToOriginals.append([origIdx])
      }
    }

    // No unknown words, or all empty strings: return right away
    if uniqueTokens.isEmpty { return unknownWordsIndex }

    guard let ai = ToolBox.ai else {
      print("⚠️ ToolBox.ai not configured")
      return unknownWordsIndex
    }

    // 3) Build the prompt; ask only for line numbers
    let systemPrompt = """
    你是词汇熟悉度助手。根据“用户背景”，从给定的每一行单词中，选择那些“用户几乎肯定已经会”的词，不要添加不确定的。
    仅返回 JSON 且只包含这些行号，字段为 known_lines，例如：
    { "known_lines": [0, 3, 7] }
    不要返回其它字段
    """

    let numbered = uniqueTokens.enumerated().map { "\($0): \($1)" }.joined(separator: "\n")
    let userPrompt = """
    ***谨慎删除***
    ***谨慎删除***
    ***谨慎删除***
    用户背景：\(background)
    待判断（去重后，按行编号）：
    \(numbered)
    """

    let body: [String: Any] = [
      "model": "gpt-4o-mini",
      "temperature": 0.0,
      "top_p": 0.0,
      "response_format": ["type": "json_object"],
      "messages": [
        ["role": "system", "content": systemPrompt],
        ["role": "user",   "content": userPrompt]
      ]
    ]

    do {
      let resp: ChatResponse = try await ai.sendRequest(
        endpoint: "chat/completions",
        body: body,
        decode: ChatResponse.self
      )
      guard let raw = resp.choices.first?.message.content else {
        return unknownWordsIndex
      }

      // 4) Parse known_lines and map them back to the original indexes
      let parsed = try JSONDecoder().decode(AIPossibleKnownResponse.self, from: Data(raw.utf8))
      var toRemove = Set<Int>()
      for line in parsed.known_lines where line >= 0 && line < uniqueLineToOriginals.count {
        for orig in uniqueLineToOriginals[line] {
          toRemove.insert(orig)
        }
      }

      // 5) Filter unknownWordsIndex
      let filtered = unknownWordsIndex.filter { !toRemove.contains($0) }
      print(userPrompt)
      print(parsed)
      print(unknownWordsIndex)
      print(filtered)
      return filtered

    } catch {
      print("❌ possibleAIFilter failed:", error.localizedDescription)
      return unknownWordsIndex
    }
  }
}
