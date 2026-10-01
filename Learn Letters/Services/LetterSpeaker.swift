//
//  LetterSpeaker.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/06/2026.
//

import AVFoundation
import Combine

struct SpeechVoiceOption: Identifiable, Hashable {
    let identifier: String
    let name: String
    let language: String
    let quality: AVSpeechSynthesisVoiceQuality
    let gender: AVSpeechSynthesisVoiceGender

    var id: String { identifier }

    var qualityLabel: String {
        switch quality {
        case .premium:
            return "Premium"
        case .enhanced:
            return "Enhanced"
        case .default:
            return "Default"
        @unknown default:
            return "Unknown"
        }
    }

    var subtitle: String {
        "\(language) • \(genderLabel) • \(qualityLabel)"
    }

    var genderLabel: String {
        switch gender {
        case .female:
            return "Female"
        case .male:
            return "Male"
        default:
            return "Unspecified"
        }
    }
}

@MainActor
final class LetterSpeaker: ObservableObject {

    private let synthesizer = AVSpeechSynthesizer()
    private var preferredVoice: AVSpeechSynthesisVoice?
    private var previewVoiceIdentifier: String?
    private let allVoices: [AVSpeechSynthesisVoice]
    @Published private(set) var selectedVoiceIdentifier: String?
    @Published var isSpeechEnabled = true {
        didSet {
            if !isSpeechEnabled {
                synthesizer.stopSpeaking(at: .immediate)
                previewVoiceIdentifier = nil
            }
        }
    }
    let voiceOptions: [SpeechVoiceOption]
    var recommendedVoiceIdentifier: String? {
        Self.bestVoice(from: allVoices)?.identifier
    }

    private let letterRate = 0.44
    private let wordRate = 0.46
    private let pitch = 1.0
    private let postDelay = 0.6

    init(preferredVoiceIdentifier: String? = nil) {
        allVoices = AVSpeechSynthesisVoice.speechVoices()
        voiceOptions = allVoices
            .sorted(by: Self.voiceSort)
            .map(Self.makeVoiceOption)

        logAvailableVoices()

        selectVoice(identifier: preferredVoiceIdentifier)
    }

    func selectVoice(identifier: String?) {
        let chosenVoice: AVSpeechSynthesisVoice?

        if let identifier,
           let matchingVoice = allVoices.first(where: { $0.identifier == identifier }) {
            chosenVoice = matchingVoice
        } else {
            chosenVoice = Self.bestVoice(from: allVoices)
        }

        synthesizer.stopSpeaking(at: .immediate)
        previewVoiceIdentifier = nil
        preferredVoice = chosenVoice
        selectedVoiceIdentifier = chosenVoice?.identifier
        if let chosenVoice {
            print("Selected voice: \(chosenVoice.name) (\(chosenVoice.language))")
        }
    }

    func voiceOption(for identifier: String) -> SpeechVoiceOption? {
        voiceOptions.first(where: { $0.identifier == identifier })
    }

    func previewVoice(identifier: String) {
        guard isSpeechEnabled else { return }

        if previewVoiceIdentifier == identifier, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            previewVoiceIdentifier = nil
            return
        }

        guard let voice = allVoices.first(where: { $0.identifier == identifier }) else { return }

        synthesizer.stopSpeaking(at: .immediate)
        previewVoiceIdentifier = identifier
        let utterance = AVSpeechUtterance(string: "Hello! Let's learn our letters and numbers together. A is for apple.")
        utterance.voice = voice
        utterance.rate = Float(wordRate)
        utterance.pitchMultiplier = Float(pitch)
        synthesizer.speak(utterance)
    }

    func isPreviewingVoice(identifier: String) -> Bool {
        previewVoiceIdentifier == identifier && synthesizer.isSpeaking
    }

    func speak(letterFor letter: LetterCard) {
        guard isSpeechEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: "\(letter.letter).")
        utterance.voice = preferredVoice
        utterance.rate = Float(letterRate)
        utterance.pitchMultiplier = Float(pitch)

        synthesizer.speak(utterance)
    }
    
    func speak(phraseFor letter: LetterCard) {
        guard isSpeechEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: "\(letter.letter).")
        utterance.voice = preferredVoice
        utterance.rate = Float(letterRate)
        utterance.pitchMultiplier = Float(pitch)
        utterance.postUtteranceDelay = postDelay
        
        let utterance2 = AVSpeechUtterance(string: "is for \(letter.word).")
        utterance2.voice = preferredVoice
        utterance2.rate = Float(wordRate)
        utterance2.pitchMultiplier = Float(pitch)
        print("Speaking: \(letter.letter) is for \(letter.word)")

        synthesizer.speak(utterance)
        synthesizer.speak(utterance2)
    }
    
    func speak(numberFor number: NumberCard) {
        guard isSpeechEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: "\(number.displayNumber).")
        utterance.voice = preferredVoice
        utterance.rate = Float(letterRate)
        utterance.pitchMultiplier = Float(pitch)

        synthesizer.speak(utterance)
    }
    
    func speak(phraseFor number: NumberCard) {
        guard isSpeechEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: "\(number.displayNumber).")
        utterance.voice = preferredVoice
        utterance.rate = Float(letterRate)
        utterance.pitchMultiplier = Float(pitch)
        utterance.postUtteranceDelay = postDelay
        print("Speaking: \(number.displayNumber)")

        synthesizer.speak(utterance)
    }

    func speak(shapeFor shape: ShapeCard) {
        guard isSpeechEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: "\(shape.label).")
        utterance.voice = preferredVoice
        utterance.rate = Float(wordRate)
        utterance.pitchMultiplier = Float(pitch)

        synthesizer.speak(utterance)
    }

    func speak(phraseFor shape: ShapeCard) {
        guard isSpeechEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: "\(shape.label).")
        utterance.voice = preferredVoice
        utterance.rate = Float(wordRate)
        utterance.pitchMultiplier = Float(pitch)
        utterance.postUtteranceDelay = postDelay

        synthesizer.speak(utterance)
    }

    func speak(colourFor colour: ColourCard) {
        guard isSpeechEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: "\(colour.label).")
        utterance.voice = preferredVoice
        utterance.rate = Float(wordRate)
        utterance.pitchMultiplier = Float(pitch)
        synthesizer.speak(utterance)
    }

    private func logAvailableVoices() {
        let details = voiceOptions
            .map { "\($0.name) [\($0.subtitle)]" }
            .joined(separator: ", ")
        print("Available voices: \(details)")
    }

    private static func makeVoiceOption(from voice: AVSpeechSynthesisVoice) -> SpeechVoiceOption {
        SpeechVoiceOption(
            identifier: voice.identifier,
            name: voice.name,
            language: voice.language,
            quality: voice.quality,
            gender: voice.gender
        )
    }

    private static func voiceSort(_ lhs: AVSpeechSynthesisVoice, _ rhs: AVSpeechSynthesisVoice) -> Bool {
        voiceScore(lhs) > voiceScore(rhs)
    }

     private static func voiceScore(_ voice: AVSpeechSynthesisVoice) -> Int {
         var score = 0

         if voice.gender == .female {
             score += 10_000
         }

         // Prioritize UK English (en-GB) over US (en-US) over other English
         if voice.language.hasPrefix("en-GB") {
             score += 5_000
         } else if voice.language.hasPrefix("en-US") {
             score += 4_000
         } else if voice.language.hasPrefix("en") {
             score += 3_000
         }

         switch voice.quality {
         case .premium:
             score += 300
         case .enhanced:
             score += 200
         case .default:
             score += 100
         @unknown default:
             score += 50
         }

         return score
     }

    private static func bestVoice(from voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        let englishVoices = voices.filter { $0.language.hasPrefix("en") }
        let candidates = englishVoices.isEmpty ? voices : englishVoices
        return candidates.sorted(by: voiceSort).first
    }
    
}
