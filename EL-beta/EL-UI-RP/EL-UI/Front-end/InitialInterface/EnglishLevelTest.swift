//
//  EnglishLevelTest.swift
//  EL-UI
//
//  Created by WJR on 11/22/24.
//

import SwiftUI

struct EnglishLevelTest: View {
    @State private var selectedSystem: LearningSystem? = nil
    @State private var selectedLevel: VocabularyLevel? = nil
    @ObservedObject var userSettings = UserSettings.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedSystem == nil {
                    // First screen: choose the English variety
                    Text("请选择语言系统")
                        .font(.headline)
                        .padding()
                    
                    Button("英式英语") {
                        selectedSystem = .UK
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    
                    Button("美式英语") {
                        selectedSystem = .US
                    }
                    .buttonStyle(.bordered)
                    .padding()
                } else {
                    // Second screen: choose the vocabulary level
                    Text("请选择词汇水平")
                        .font(.headline)
                        .padding()
                    
                    if selectedSystem == .UK {
                        vocabularyButtons(levels: [
                            "1000", "3000", "4000", "6000"
                        ])
                    } else if selectedSystem == .US {
                        vocabularyButtons(levels: [
                            "1000", "4000", "6000"
                        ])
                    }
                }
            }
            .navigationBarTitle("英语水平测试", displayMode: .inline)
            .toolbar {
                // Back button
                if selectedSystem != nil {
                    Button("返回") {
                        selectedSystem = nil
                        selectedLevel = nil
                    }
                }
            }
        }
    }
    
    // Helper function for vocabulary level buttons
    func vocabularyButtons(levels: [String]) -> some View {
        VStack {
            ForEach(levels, id: \.self) { level in
                Button("\(selectedSystem == .UK ? "英式" : "美式") > \(level)") {
                    saveUserLevel(level: level)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
    }
    
    func saveUserLevel(level: String) {
        // Save the user's choice
        let vocabularyLevel: VocabularyLevel
        switch level {
        case "1000": vocabularyLevel = .beginner
        case "3000", "4000": vocabularyLevel = .intermediate
        default: vocabularyLevel = .advanced
        }
        
        userSettings.userEnglishLevel = UserEnglishLevel(
            learningSystem: selectedSystem ?? .US,
            vocabularyLevel: vocabularyLevel
        )
        print(UserSettings.shared.userEnglishLevel)
        // Reset the choices
        selectedSystem = nil
        selectedLevel = nil
    }
}

#Preview {
    EnglishLevelTest()
}
