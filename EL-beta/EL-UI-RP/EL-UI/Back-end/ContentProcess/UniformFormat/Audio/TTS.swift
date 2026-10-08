//
//  TTS.swift
//  EL-UI
//
//  Created by WJR on 4/7/24.
//

import AVFoundation

class TextToSpeechManager: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  
  override init() {
    super.init()
    synthesizer.delegate = self
  }
  
  func speak(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // set the language
    synthesizer.speak(utterance)
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    print("Finished speaking \(utterance.speechString)")
  }
}
