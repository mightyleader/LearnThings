//
//  LearningPalette.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/09/2026.
//

import SwiftUI

enum LearningPalette {
    private static let fallbackLetterColorTokens: [String: String] = [
        "A": "#004D80", "B": "#0076BA", "C": "#00A2FF", "D": "#56C1FF", "E": "#73FDEA",
        "F": "#16E7CF", "G": "#00AB8E", "H": "#006C65", "I": "#88FA4E", "J": "#61D836",
        "K": "#1DB100", "L": "#017100", "M": "#C98A00", "N": "#FFD932", "O": "#FEAE00",
        "P": "#F27200", "Q": "#FF968D", "R": "#FF644E", "S": "#EE220C", "T": "#B51700",
        "U": "#FF95CA", "V": "#FF42A1", "W": "#D31876", "X": "#970E53", "Y": "#929292",
        "Z": "#000000"
    ]

    private static let fallbackNumberColorTokens: [Int: String] = [
        0: "#FF0000", 1: "#FF7F00", 2: "#EBC015", 3: "#00FF00", 4: "#0000FF",
        5: "#4B0082", 6: "#9400D3", 7: "#FF1493", 8: "#FF69B4", 9: "#00CED1",
        10: "#32CD32"
    ]

    private static let fallbackShapeColorTokens: [ShapeKind: String] = [
        .circle: "#004D80",
        .oval: "#16E7CF",
        .triangle: "#F27200",
        .square: "#0F7A73",
        .rectangle: "#61D836",
        .diamond: "#FFD932",
        .arrow: "#1DB100",
        .heart: "#EE220C",
        .crescent: "#9B9B9B",
        .star: "#FEAE00",
        .cloud: "#56C1FF",
        .pentagon: "#B51700",
        .hexagon: "#9B9700",
        .octagon: "#1D96F0",
        .rhombus: "#FF2200"
    ]

    private static let loadedLetterColors = loadLetterColorsFile(named: "LetterColors")
    private static let fallbackLetterColors = makeColorMap(from: fallbackLetterColorTokens)
    private static let fallbackNumberColors = makeColorMap(from: fallbackNumberColorTokens)
    private static let fallbackShapeColors = makeColorMap(from: fallbackShapeColorTokens)

    static func color(forLetter letter: String) -> Color {
        let key = letter.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return loadedLetterColors[key] ?? fallbackLetterColors[key] ?? .primary
    }

    static func color(forNumber number: Int) -> Color {
        fallbackNumberColors[number] ?? .primary
    }

    static func color(forShape kind: ShapeKind) -> Color {
        fallbackShapeColors[kind] ?? .primary
    }

    static func colorFromString(_ string: String) -> Color? {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch normalized {
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
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

    private static func makeColorMap<Key: Hashable>(from tokens: [Key: String]) -> [Key: Color] {
        tokens.reduce(into: [:]) { partial, pair in
            partial[pair.key] = colorFromString(pair.value) ?? .primary
        }
    }

    private static func loadLetterColorsFile(named filename: String) -> [String: Color] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            print("Warning: \(filename).txt missing or unreadable; using palette fallback colors")
            return [:]
        }

        var colors: [String: Color] = [:]

        for (idx, rawLine) in text.components(separatedBy: .newlines).enumerated() {
            let lineNumber = idx + 1
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            guard let separator = trimmed.firstIndex(of: "=") else {
                print("Warning: \(filename).txt:\(lineNumber) missing '=' -> \(rawLine)")
                continue
            }

            let key = String(trimmed[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let token = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard key.count == 1 else {
                print("Warning: \(filename).txt:\(lineNumber) invalid key '\(key)'; expected A-Z")
                continue
            }

            guard let color = colorFromString(token) else {
                print("Warning: \(filename).txt:\(lineNumber) invalid color '\(token)' for key '\(key)'")
                continue
            }

            colors[key] = color
        }

        return colors
    }
}
