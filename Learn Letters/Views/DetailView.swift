//
//  DetailView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI
import UIKit

struct DetailView: View {
    let currentLetter: LetterCard
    @FocusState var focusedTarget: FocusTarget?
    var onDetailMove: (MoveCommandDirection) -> Void
    var onDetailPlayPause: () -> Void
    var onExit: () -> Void
    var onSpeak: () -> Void

    private let tileFontName = "AkzidenzGroteskBE-Bold"
    private let wordFontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geo in
            let letterSize = geo.size.height * Layout.detailLetterHeightRatio
            let wordSize   = geo.size.height * Layout.detailWordHeightRatio

            Button(action: onSpeak) {
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
            .onMoveCommand(perform: onDetailMove)
            .onPlayPauseCommand(perform: onDetailPlayPause)
            .onExitCommand(perform: onExit)
            .onAppear(perform: onSpeak)
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
}
