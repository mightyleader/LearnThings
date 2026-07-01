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

private enum Layout {
    static let gridHorizontalPadding: CGFloat = 60
    static let gridVerticalPadding: CGFloat = 60
    static let gridGap: CGFloat = 10
    static let gridColumns: Int = 6
    static let gridTileCornerRadius: CGFloat = 5
    static let gridLetterScale: CGFloat = 0.80

    static let detailLetterHeightRatio: CGFloat = 0.80
    static let detailWordHeightRatio: CGFloat = 0.07
    static let detailVStackSpacingRatio: CGFloat = 0.03
    static let detailHStackSpacingRatio: CGFloat = 0.04

}

struct ContentView: View {
    @StateObject private var speaker = LetterSpeaker()
    @State private var selectedIndex = 0
    @State private var showingGrid = true
    @FocusState private var focusedTarget: FocusTarget?

    private let alphabet = LetterCard.samples
    private let letterFontName = "AkzidenzGroteskBE-Md"
    private let tileFontName = "AkzidenzGroteskBE-Bold"
    private let wordFontName = "AkzidenzGroteskBE-Bold"

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
                speaker.speak(letterFor: alphabet[newValue])
            }
        }
    }

    private var alphabetGridScreen: some View {
        GeometryReader { geo in
            let hPad = Layout.gridHorizontalPadding
            let vPad = Layout.gridVerticalPadding
            let gap = Layout.gridGap
            let cols = CGFloat(Layout.gridColumns)
            let rows = CGFloat(Int(ceil(Double(alphabet.count) / Double(Layout.gridColumns))))

            let cellWidth  = (geo.size.width  - hPad * 2 - gap * (cols - 1)) / cols
            let cellHeight = (geo.size.height - vPad * 2 - gap * (rows - 1)) / rows
            let fontSize   = cellHeight * Layout.gridLetterScale

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gap), count: Layout.gridColumns),
                spacing: gap
            ) {
                ForEach(Array(alphabet.enumerated()), id: \.element.letter) { index, item in
                    let isFocused = focusedTarget == .tile(item.letter)

                    Button {
                        selectedIndex = index
                        showingGrid = false
                        focusedTarget = .hero
//                        speaker.speak(item)
                    } label: {
                        LetterPairLabel(
                            uppercase: item.uppercaseLetter,
                            lowercase: item.lowercaseLetter,
                            separator: "",
                            uppercaseColor: UIColor(item.color),
                            lowercaseColor: UIColor(item.color.opacity(0.35)),
                            font: uiFontOrFallback(name: tileFontName, size: fontSize, fallbackWeight: .bold),
                            minimumScaleFactor: 0.8,
                            horizontalInset: max(2, fontSize * 0.08)
                        )
                        .frame(width: cellWidth, height: cellHeight)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.gridTileCornerRadius, style: .continuous)
                                .fill(Color.clear)
                        )
                        .animation(.easeInOut(duration: 0.10), value: isFocused)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedTarget, equals: .tile(item.letter))
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .onMoveCommand(perform: handleGridMove)
        }
    }

    private var letterDetailScreen: some View {
        GeometryReader { geo in
            let letterSize = geo.size.height * Layout.detailLetterHeightRatio
            let wordSize   = geo.size.height * Layout.detailWordHeightRatio

            Button {
                speaker.speak(phraseFor: currentLetter)
            } label: {
                VStack(spacing: geo.size.height * Layout.detailVStackSpacingRatio) {
                    LetterPairLabel(
                        uppercase: currentLetter.uppercaseLetter,
                        lowercase: currentLetter.lowercaseLetter,
                        separator: " ",
                        uppercaseColor: UIColor(currentLetter.color),
                        lowercaseColor: UIColor(currentLetter.color.opacity(0.35)),
                        font: uiFontOrFallback(name: tileFontName, size: letterSize, fallbackWeight: .heavy),
                        minimumScaleFactor: 0.4,
                        horizontalInset: max(4, letterSize * 0.08)
                    )
                    .padding()

                    Text(currentLetter.word)
                        .font(fontOrFallback(name: wordFontName, size: wordSize, fallbackWeight: .regular))
                        .foregroundStyle(.black)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .buttonStyle(.borderless)
            .focused($focusedTarget, equals: .hero)
            .onMoveCommand(perform: handleHeroMove)
            .onExitCommand {
                showingGrid = true
                focusedTarget = .tile(currentLetter.letter)
            }
            .onAppear() {
                speaker.speak(phraseFor: currentLetter)
            }
        }
    }

    private func fontOrFallback(name: String, size: CGFloat, fallbackWeight: Font.Weight) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }

        return .system(size: size, weight: fallbackWeight, design: .default)
    }

    private func uiFontOrFallback(name: String, size: CGFloat, fallbackWeight: UIFont.Weight) -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: fallbackWeight)
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

    private func handleGridMove(_ direction: MoveCommandDirection) {
        guard !alphabet.isEmpty else { return }

        let columns = Layout.gridColumns
        let count = alphabet.count
        let lastIndex = count - 1

        // Keep movement deterministic to avoid double-focus drift.
        let currentIndex = selectedIndex
        let row = currentIndex / columns
        let col = currentIndex % columns

        let totalRows = Int(ceil(Double(count) / Double(columns)))

        func rowEndIndex(_ r: Int) -> Int {
            min(((r + 1) * columns) - 1, lastIndex)
        }

        func hasCell(row: Int, col: Int) -> Bool {
            let idx = row * columns + col
            return idx >= 0 && idx < count
        }

        func nextValidRowDown(from startRow: Int, col: Int) -> Int {
            for step in 1...totalRows {
                let candidate = (startRow + step) % totalRows
                if hasCell(row: candidate, col: col) { return candidate }
            }
            return startRow
        }

        func nextValidRowUp(from startRow: Int, col: Int) -> Int {
            for step in 1...totalRows {
                let candidate = (startRow - step + totalRows) % totalRows
                if hasCell(row: candidate, col: col) { return candidate }
            }
            return startRow
        }

        let target: Int

        switch direction {
        case .left:
            target = (col == 0) ? rowEndIndex(row) : (currentIndex - 1)
        case .right:
            target = (currentIndex == rowEndIndex(row)) ? (row * columns) : (currentIndex + 1)
        case .up:
            let targetRow = nextValidRowUp(from: row, col: col)
            target = (targetRow * columns) + col
        case .down:
            let targetRow = nextValidRowDown(from: row, col: col)
            target = (targetRow * columns) + col
        default:
            return
        }

        selectedIndex = target
        focusedTarget = .tile(alphabet[target].letter)
    }
}

private struct LetterPairLabel: UIViewRepresentable {
    let uppercase: String
    let lowercase: String
    let separator: String
    let uppercaseColor: UIColor
    let lowercaseColor: UIColor
    let font: UIFont
    let minimumScaleFactor: CGFloat
    let horizontalInset: CGFloat

    func makeUIView(context: Context) -> InsetLabel {
        let label = InsetLabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        label.lineBreakMode = .byClipping
        label.clipsToBounds = false
        return label
    }

    func updateUIView(_ label: InsetLabel, context: Context) {
        label.minimumScaleFactor = minimumScaleFactor
        label.textInsets = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)

        let text = NSMutableAttributedString(
            string: uppercase,
            attributes: [
                .font: font,
                .foregroundColor: uppercaseColor
            ]
        )
        text.append(
            NSAttributedString(
                string: separator + lowercase,
                attributes: [
                    .font: font,
                    .foregroundColor: lowercaseColor
                ]
            )
        )

        label.attributedText = text
    }
}

private final class InsetLabel: UILabel {
    var textInsets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
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

@MainActor
private final class LetterSpeaker: ObservableObject {

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
        
        let utterance2 = AVSpeechUtterance(string: "\(letter.letter) is for \(letter.word).")
        utterance2.voice = preferredVoice
        utterance2.rate = Float(wordRate)
        utterance2.pitchMultiplier = Float(pitch)
        print("Speaking: \(letter.letter) is for \(letter.word)")

        synthesizer.speak(utterance)
        synthesizer.speak(utterance2)
    }
    
}

#Preview {
    ContentView()
}
