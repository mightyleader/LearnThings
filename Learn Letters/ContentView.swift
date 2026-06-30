//
//  ContentView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var speaker = LetterSpeaker()
    @State private var selectedIndex = 0
    @State private var showingGrid = true
    @FocusState private var focusedTarget: FocusTarget?

    private let alphabet = LetterCard.samples
    private let letterFontName = "AkzidenzGroteskBE-Md"
    private let tileFontName = "AkzidenzGroteskBE-Bold"
    private let wordFontName = "AkzidenzGroteskBE-Light"

    private var currentLetter: LetterCard {
        alphabet[selectedIndex]
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showingGrid {
                alphabetGridScreen
            } else {
                letterDetailScreen
            }
        }
        .onAppear {
            focusedTarget = .tile(alphabet[selectedIndex].letter)
        }
        .onChange(of: selectedIndex) { _, newValue in
            if !showingGrid {
                speaker.speak(alphabet[newValue])
            }
        }
    }

    private var alphabetGridScreen: some View {
        GeometryReader { geo in
            let hPad: CGFloat = 60
            let vPad: CGFloat = 60
            let gap:  CGFloat = 0
            let cols: CGFloat = 6
            let rows: CGFloat = 5  // 26 letters → 5 rows (last row has 2)

            let cellWidth  = (geo.size.width  - hPad * 2 - gap * (cols - 1)) / cols
            let cellHeight = (geo.size.height - vPad * 2 - gap * (rows - 1)) / rows
            let fontSize   = cellHeight * 0.85

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gap), count: Int(cols)),
                spacing: gap
            ) {
                ForEach(Array(alphabet.enumerated()), id: \.element.letter) { index, item in
                    let isFocused = focusedTarget == .tile(item.letter)

                    Button {
                        selectedIndex = index
                        showingGrid = false
                        focusedTarget = .hero
                        speaker.speak(item)
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.uppercaseLetter)
                            Text(item.lowercaseLetter)
                                .opacity(0.7)
                        }
                        .font(fontOrFallback(name: tileFontName, size: fontSize, fallbackWeight: .bold))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(item.color)
                        .frame(width: cellWidth, height: cellHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.clear)
                        )
                        .animation(.easeInOut(duration: 0.18), value: isFocused)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedTarget, equals: .tile(item.letter))
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
        }
    }

    private var letterDetailScreen: some View {
        GeometryReader { geo in
            // Letters occupy ~80% of screen height; split between the two glyphs side by side
            let letterSize = geo.size.height * 0.80
            let wordSize   = geo.size.height * 0.07

            Button {
                speaker.speak(currentLetter)
            } label: {
                VStack(spacing: geo.size.height * 0.03) {
                    HStack(spacing: geo.size.width * 0.04) {
                        Text(currentLetter.uppercaseLetter)
                            .font(fontOrFallback(name: tileFontName, size: letterSize, fallbackWeight: .heavy))
                            .foregroundStyle(currentLetter.color)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text(currentLetter.lowercaseLetter)
                            .font(fontOrFallback(name: tileFontName, size: letterSize, fallbackWeight: .heavy))
                            .foregroundStyle(currentLetter.color.opacity(0.7))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }

                    Text(currentLetter.word)
                        .font(fontOrFallback(name: wordFontName, size: wordSize, fallbackWeight: .regular))
                        .foregroundStyle(.black)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .buttonStyle(.plain)
            .focused($focusedTarget, equals: .hero)
            .onMoveCommand(perform: handleHeroMove)
            .onExitCommand {
                showingGrid = true
                focusedTarget = .tile(currentLetter.letter)
            }
        }
    }

    private func fontOrFallback(name: String, size: CGFloat, fallbackWeight: Font.Weight) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }

        return .system(size: size, weight: fallbackWeight, design: .default)
    }

    private func handleHeroMove(_ direction: MoveCommandDirection) {
        switch direction {
        case .left:
            previousLetter()
        case .right:
            nextLetter()
        default:
            break
        }
    }

    private func previousLetter() {
        selectedIndex = (selectedIndex - 1 + alphabet.count) % alphabet.count
    }

    private func nextLetter() {
        selectedIndex = (selectedIndex + 1) % alphabet.count
    }
}

private enum FocusTarget: Hashable {
    case hero
    case tile(String)
}

private struct LetterCard: Identifiable {
    let letter: String
    let word: String
    let color: Color

    var id: String { letter }
    var uppercaseLetter: String { letter.uppercased() }
    var lowercaseLetter: String { letter.lowercased() }
}

private extension LetterCard {

    // MARK: - Fallback data (used if text files are missing or incomplete)

    private static let fallbackWords: [String: String] = [
        "A": "Apple", "B": "Ball", "C": "Cat", "D": "Dog", "E": "Egg",
        "F": "Fish", "G": "Grapes", "H": "Hat", "I": "Ice Cream", "J": "Jam",
        "K": "Kite", "L": "Lion", "M": "Moon", "N": "Nest", "O": "Orange",
        "P": "Penguin", "Q": "Queen", "R": "Rainbow", "S": "Sun", "T": "Tree",
        "U": "Umbrella", "V": "Violin", "W": "Whale", "X": "Xylophone",
        "Y": "Yarn", "Z": "Zebra"
    ]

    private static let fallbackColors: [String: Color] = [
        "A": .red, "B": .blue, "C": .purple, "D": .orange, "E": .mint,
        "F": .teal, "G": .indigo, "H": .cyan, "I": .pink, "J": .red,
        "K": .teal, "L": .yellow, "M": .indigo, "N": .brown, "O": .orange,
        "P": .gray, "Q": .yellow, "R": .pink, "S": .orange, "T": .green,
        "U": .blue, "V": .brown, "W": .cyan, "X": .purple, "Y": .pink,
        "Z": .black
    ]

    // MARK: - Text file loaders

    private static func loadKeyValueFile(named filename: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return [:] }

        var result: [String: String] = [:]
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces).uppercased()
            let value = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)
            result[key] = value
        }
        return result
    }

    private static func colorFromString(_ string: String) -> Color? {
        let s = string.trimmingCharacters(in: .whitespaces).lowercased()
        // Named colors
        switch s {
        case "red":     return .red
        case "orange":  return .orange
        case "yellow":  return .yellow
        case "green":   return .green
        case "mint":    return .mint
        case "teal":    return .teal
        case "cyan":    return .cyan
        case "blue":    return .blue
        case "indigo":  return .indigo
        case "purple":  return .purple
        case "pink":    return .pink
        case "brown":   return .brown
        case "gray", "grey": return .gray
        case "black":   return .black
        case "white":   return .white
        default: break
        }
        // Hex colors: #RRGGBB or #RRGGBBAA
        let hex = string.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6 || hex.count == 8,
              let value = UInt64(hex, radix: 16)
        else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8)  & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        let a = hex.count == 8 ? Double((value >> 24) & 0xFF) / 255 : 1.0
        return Color(red: r, green: g, blue: b, opacity: a)
    }

    // MARK: - Card factory

    static let samples: [LetterCard] = {
        let letters = (Unicode.Scalar("A").value...Unicode.Scalar("Z").value)
            .compactMap { Unicode.Scalar($0).map { String($0) } }

        let words  = loadKeyValueFile(named: "LetterWords")
        let colors = loadKeyValueFile(named: "LetterColors")

        return letters.map { letter in
            let word  = words[letter]  ?? fallbackWords[letter]  ?? letter
            let color = colors[letter].flatMap { colorFromString($0) }
                     ?? fallbackColors[letter]
                     ?? .primary
            return LetterCard(letter: letter, word: word, color: color)
        }
    }()
}

@MainActor
private final class LetterSpeaker: ObservableObject {
    
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ letter: LetterCard) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: "\(letter.letter). \(letter.word).")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.08

        synthesizer.speak(utterance)
    }
}

#Preview {
    ContentView()
}

