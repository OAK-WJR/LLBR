//
//  EnglishLevelTest.swift
//  EL-UI
//
//  Created by WJR on 11/22/24.
//

import SwiftUI

struct EnglishLevelTest: View {
  // Flow: system -> level -> background
  enum Step { case system, level, background }

  @State private var step: Step = .system

  // The user's current choices (held for now, saved all at once on the background page)
  @State private var selectedSystem: LearningSystem? = nil
  @State private var selectedLevel: VocabularyLevel? = nil

  @ObservedObject var userSettings = UserSettings.shared

  // Draft of the background text
  @State private var draftBackground = ""

  var body: some View {
    NavigationView {
      VStack(spacing: 16) {
        Spacer(minLength: 0)
        
        switch step {
        case .system:
          Text("请选择语言系统").font(.headline)
          Button("英式英语") { selectedSystem = .UK; step = .level }
            .buttonStyle(.bordered).padding(.top, 8)
          Button("美式英语") { selectedSystem = .US; step = .level }
            .buttonStyle(.bordered)

        case .level:
          Text("请选择词汇水平").font(.headline)
          if selectedSystem == .UK {
            vocabularyButtons(levels: ["1000", "3000", "4000", "6000"])
          } else {
            vocabularyButtons(levels: ["1000", "4000", "6000"])
          }

        case .background:
          VStack(alignment: .leading, spacing: 12) {
            Text("请简单描述你的英语学习经历").font(.headline)

            ZStack(alignment: .topLeading) {
              TextEditor(text: $draftBackground)
                .frame(minHeight: 160)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.2)))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            }

            let minCount = 0 // Change this for a minimum length, e.g. 20
            let trimmed = draftBackground.trimmingCharacters(in: .whitespacesAndNewlines)

            HStack {
              Text(minCount > 0 && trimmed.count < minCount ? "至少输入 \(minCount) 个字符" : " ")
                .font(.footnote).foregroundColor(.secondary)
              Spacer()
              Text("\(trimmed.count) 字")
                .font(.footnote).foregroundColor(.secondary)
            }

            HStack {
              Button("跳过") {
                finishAndPersist(background: nil)
              }
              Spacer()
              Button("保存") {
                finishAndPersist(background: trimmed)
              }
              .buttonStyle(.borderedProminent)
              .disabled(minCount > 0 && trimmed.count < minCount)
            }
          }
        }

        Spacer(minLength: 0)
      }
      .padding()
      .navigationBarTitle("英语水平测试", displayMode: .inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          if step != .system {
            Button("返回") {
              switch step {
              case .level: step = .system
              case .background: step = .level
              case .system: break
              }
            }
          }
        }
      }
    }
  }

  // Level buttons
  func vocabularyButtons(levels: [String]) -> some View {
    VStack {
      ForEach(levels, id: \.self) { levelStr in
        Button("\(selectedSystem == .UK ? "英式" : "美式") > \(levelStr)") {
          // Hold the level for now instead of writing it to userSettings right away; go to the background page
          selectedLevel = mapLevel(levelStr)
          step = .background
        }
        .buttonStyle(.bordered)
        .padding(.vertical, 4)
      }
    }
  }

  // Map the string to a VocabularyLevel
  func mapLevel(_ level: String) -> VocabularyLevel {
    switch level {
      case "1000": return .beginner
      case "3000", "4000": return .intermediate
      default: return .advanced
    }
  }

  // Save everything at once at the end and let the parent view switch away
  func finishAndPersist(background: String?) {
    guard let sys = selectedSystem, let lvl = selectedLevel else { return }
    if let bg = background {
      userSettings.background = bg
    } else {
      // Also store a placeholder when skipping, so the outer "is it empty" check does not send the user back here
      if userSettings.background.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        userSettings.background = "None"
      }
    }
    userSettings.userEnglishLevel = UserEnglishLevel(learningSystem: sys, vocabularyLevel: lvl)

    // Clear local state (optional)
    selectedSystem = nil
    selectedLevel = nil
    // Hand control back to the parent view, which switches to the main screen based on your outer condition
  }
}

#Preview {
  EnglishLevelTest()
}
