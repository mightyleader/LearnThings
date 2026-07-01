//
//  LetterCard.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct LetterCard: Identifiable {
    let letter: String
    let word: String
    let color: Color

    var id: String { letter }
    var uppercaseLetter: String { letter.uppercased() }
    var lowercaseLetter: String { letter.lowercased() }
}

extension LetterCard {

    // MARK: - Fallback data (used if text files are missing or incomplete)

    private static let fallbackWords: [String: String] = [
        "A": "Apple", "B": "Ball", "C": "Cat", "D": "Dog", "E": "Egg",
        "F": "Fish", "G": "Grapes", "H": "Hat", "I": "Ice Cream", "J": "Jam",
        "K": "Kite", "L": "Lion", "M": "Moon", "N": "Nest", "O": "Orange",
        "P": "Penguin", "Q": "Queen", "R": "Rainbow", "S": "Sun", "T": "Tree",
        "U": "Umbrella", "V": "Violin", "W": "Whale", "X": "Xylophone",
        "Y": "Yarn", "Z": "Zebra"
    ]

    private static let fallbackColorTokens: [String: String] = [
        "A": "#004D80", "B": "#0076BA", "C": "#00A2FF", "D": "#56C1FF", "E": "#73FDEA",
        "F": "#16E7CF", "G": "#00AB8E", "H": "#006C65", "I": "#88FA4E", "J": "#61D836",
        "K": "#1DB100", "L": "#017100", "M": "#FFF056", "N": "#FFD932", "O": "#FEAE00",
        "P": "#F27200", "Q": "#FF968D", "R": "#FF644E", "S": "#EE220C", "T": "#B51700",
        "U": "#FF95CA", "V": "#FF42A1", "W": "#D31876", "X": "#970E53", "Y": "#929292",
        "Z": "#000000"
    ]

    private static let fallbackColors: [String: Color] = fallbackColorTokens.reduce(into: [:]) { partial, pair in
        partial[pair.key] = colorFromString(pair.value) ?? .primary
    }

    // MARK: - Text file loaders

    private static func parseEntries(from text: String, filename: String) -> [(key: String, value: String, line: Int)] {
        var entries: [(key: String, value: String, line: Int)] = []

        for (idx, rawLine) in text.components(separatedBy: .newlines).enumerated() {
            let lineNumber = idx + 1
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            guard let eq = trimmed.firstIndex(of: "=") else {
                print("Warning: \(filename).txt:\(lineNumber) missing '=' -> \(rawLine)")
                continue
            }

            let rawKey = String(trimmed[..<eq]).trimmingCharacters(in: .whitespaces).uppercased()
            let value = String(trimmed[trimmed.index(after: eq)...]).trimmingCharacters(in: .whitespaces)

            guard rawKey.count == 1,
                  let first = rawKey.unicodeScalars.first,
                  ("A"..."Z").contains(String(first)) else {
                print("Warning: \(filename).txt:\(lineNumber) invalid key '\(rawKey)'; expected A-Z")
                continue
            }

            guard !value.isEmpty else {
                print("Warning: \(filename).txt:\(lineNumber) empty value for key '\(rawKey)'")
                continue
            }

            entries.append((key: rawKey, value: value, line: lineNumber))
        }

        return entries
    }

    private static func loadWordsFile(named filename: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            print("Warning: \(filename).txt missing or unreadable; using fallback words")
            return [:]
        }

        let entries = parseEntries(from: text, filename: filename)
        var result: [String: String] = [:]

        for entry in entries {
            if result[entry.key] != nil {
                print("Warning: \(filename).txt:\(entry.line) duplicate key '\(entry.key)'; last value wins")
            }
            result[entry.key] = entry.value
        }

        return result
    }

    private static func loadColorFile(named filename: String) -> [String: Color] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            print("Warning: \(filename).txt missing or unreadable; using fallback colors")
            return [:]
        }

        let entries = parseEntries(from: text, filename: filename)
        var result: [String: Color] = [:]

        for entry in entries {
            guard let color = colorFromString(entry.value) else {
                print("Warning: \(filename).txt:\(entry.line) invalid color '\(entry.value)' for key '\(entry.key)'")
                continue
            }
            if result[entry.key] != nil {
                print("Warning: \(filename).txt:\(entry.line) duplicate key '\(entry.key)'; last value wins")
            }
            result[entry.key] = color
        }

        return result
    }

    // MARK: - Card factory

    static let samples: [LetterCard] = {
        let letters = (Unicode.Scalar("A").value...Unicode.Scalar("Z").value)
            .compactMap { Unicode.Scalar($0).map { String($0) } }

        let words = loadWordsFile(named: "LetterWords")
        let colors = loadColorFile(named: "LetterColors")

        return letters.map { letter in
            let word  = words[letter]  ?? fallbackWords[letter]  ?? letter
            let color = colors[letter] ?? fallbackColors[letter] ?? .primary
            return LetterCard(letter: letter, word: word, color: color)
        }
    }()

    private static func colorFromString(_ string: String) -> Color? {
        let s = string.trimmingCharacters(in: .whitespaces).lowercased()

        switch s {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        default: break
        }

        let hex = string
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))

        func parseByte(_ start: Int) -> Double? {
            let from = hex.index(hex.startIndex, offsetBy: start)
            let to = hex.index(from, offsetBy: 2)
            guard let value = UInt8(hex[from..<to], radix: 16) else { return nil }
            return Double(value) / 255
        }

        if hex.count == 6,
           let r = parseByte(0),
           let g = parseByte(2),
           let b = parseByte(4) {
            return Color(red: r, green: g, blue: b)
        }

        if hex.count == 8,
           let r = parseByte(0),
           let g = parseByte(2),
           let b = parseByte(4),
           let a = parseByte(6) {
            return Color(red: r, green: g, blue: b, opacity: a)
        }

        return nil
    }
}
