//
//  DetailView.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct DetailView: View {
    let currentLetter: LetterCard
    @FocusState var focusedTarget: FocusTarget?
    var onDetailMove: (NavigationDirection) -> Void
    var onDetailPlayPause: () -> Void
    var onExit: () -> Void
    var onSpeak: () -> Void

    private let tileFontName = "AkzidenzGroteskBE-Bold"
    private let wordFontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geo in
            let letterSize = geo.size.height * AppLayout.detailLetterHeightRatio
            let wordSize   = geo.size.height * AppLayout.detailWordHeightRatio

            Button(action: onSpeak) {
                VStack(spacing: geo.size.height * AppLayout.detailVStackSpacingRatio) {
                    LetterPairLabel(
                        uppercase: currentLetter.uppercaseLetter,
                        lowercase: currentLetter.lowercaseLetter,
                        separator: " ",
                        uppercaseColor: currentLetter.color,
                        lowercaseColor: currentLetter.color.opacity(0.35),
                        font: .custom(tileFontName, size: letterSize),
                        minimumScaleFactor: 0.4,
                        horizontalInset: max(4, letterSize * 0.08)
                    )
                    .padding()

                    Text(currentLetter.word)
                        .font(.custom(wordFontName, size: wordSize))
                        .foregroundStyle(.black)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .buttonStyle(.borderless)
            .focused($focusedTarget, equals: .hero)
            #if os(tvOS)
            .onMoveCommand { direction in
                switch direction {
                case .up: onDetailMove(.up)
                case .down: onDetailMove(.down)
                case .left: onDetailMove(.left)
                case .right: onDetailMove(.right)
                @unknown default: break
                }
            }
            .onPlayPauseCommand(perform: onDetailPlayPause)
            .onExitCommand(perform: onExit)
            #endif
            .onAppear(perform: onSpeak)
        }
    }

}
