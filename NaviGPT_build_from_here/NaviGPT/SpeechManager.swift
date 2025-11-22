//
//  SpeechManager.swift
//  NaviGPT
//
//  Created by Albert He ZHANG on 9/24/24.
//

import Foundation
import AVFoundation

final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ utterance: AVSpeechUtterance, interrupt: Bool = false) {
        DispatchQueue.main.async {
            if interrupt && self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            self.synthesizer.speak(utterance)
        }
    }

    func stopSpeaking() {
        DispatchQueue.main.async {
            self.synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // Optional: Implement delegate methods if you need to manage speech events
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Handle completion if necessary
    }
}
