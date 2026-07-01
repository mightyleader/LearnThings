//
//  LetterSpeaker.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import AVFoundation
import Combine

@MainActor
final class LetterSpeaker: ObservableObject {

    private let synthesizer = AVSpeechSynthesizer()
    private var preferredVoice: AVSpeechSynthesisVoice?
    private let letterRate = 0.2
    private let wordRate = 0.5
    private let pitch = 1.1
    private let postDelay = 0.6

    init() {
        // Select voice immediately on main thread to avoid concurrency warnings
        // This is safe because AVSpeechSynthesisVoice.speechVoices() is fast
        preferredVoice = AVSpeechSynthesisVoice.speechVoices()
            .first { $0.name.contains("Sandy") }
        ?? AVSpeechSynthesisVoice.speechVoices()
            .first { $0.name.contains("Shelley") }
        ?? AVSpeechSynthesisVoice.speechVoices()
            .first { $0.name.contains("Samantha") }
        print("Selected voice: \(preferredVoice?.name ?? "none") (\(preferredVoice?.language ?? "unknown"))")
    }

    func speak(letterFor letter: LetterCard) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: "\(letter.letter).")
        utterance.voice = preferredVoice
        utterance.rate = Float(letterRate)
        utterance.pitchMultiplier = Float(pitch)
        print("Speaking: \(letter.letter)")

        synthesizer.speak(utterance)
    }
    
    func speak(phraseFor letter: LetterCard) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: "\(letter.letter).")
        utterance.voice = preferredVoice
        utterance.rate = Float(letterRate)
        utterance.pitchMultiplier = Float(pitch)
        utterance.postUtteranceDelay = postDelay
        print("Speaking: \(letter.letter)")
        
        let utterance2 = AVSpeechUtterance(string: "is for \(letter.word).")
        utterance2.voice = preferredVoice
        utterance2.rate = Float(wordRate)
        utterance2.pitchMultiplier = Float(pitch)
        print("Speaking: \(letter.letter) is for \(letter.word)")

        synthesizer.speak(utterance)
        synthesizer.speak(utterance2)
    }
    
}
