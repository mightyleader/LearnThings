//
//  LetterCard.swift
//  Learn Things
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

    // MARK: - Card factory

    static let samples: [LetterCard] = {
        let letters = (Unicode.Scalar("A").value...Unicode.Scalar("Z").value)
            .compactMap { Unicode.Scalar($0).map { String($0) } }

        let words = loadWordsFile(named: "LetterWords")
        return letters.map { letter in
            let word  = words[letter]  ?? fallbackWords[letter]  ?? letter
            let color = LearningPalette.color(forLetter: letter)
            return LetterCard(letter: letter, word: word, color: color)
        }
    }()
}
