//
//  AIService.swift
//  EL-UI
//
//  Created by WJR on 10/28/25.
//

import Foundation

public final class AIService {
  private let apiKey: String
  private let baseURL = URL(string: "https://api.openai.com/v1")!

  public init(apiKey: String) { self.apiKey = apiKey }

  /// Generic request: the caller passes the endpoint and JSON body; this only sends the request and decodes the result
  public func sendRequest<T: Decodable>(
    endpoint: String,
    body: [String: Any],
    decode: T.Type
  ) async throws -> T {
    let url = baseURL.appendingPathComponent(endpoint)
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      let raw = String(data: data, encoding: .utf8) ?? ""
      throw NSError(domain: "AIService", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "API error: \(raw)"])
    }
    return try JSONDecoder().decode(T.self, from: data)
  }
}
