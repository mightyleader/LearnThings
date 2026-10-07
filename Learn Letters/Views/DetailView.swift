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

    var body: some View {
        GeometryReader { geo in
            let letterSize = geo.size.height * AppLayout.detailLetterHeightRatio
            let wordSize   = geo.size.height * AppLayout.detailWordHeightRatio

            ZStack {
                Color.white.ignoresSafeArea()
                
                Button(action: onSpeak) {
                    VStack(spacing: geo.size.height * AppLayout.detailVStackSpacingRatio) {
                        LetterPairLabel(
                            uppercase: currentLetter.uppercaseLetter,
                            lowercase: currentLetter.lowercaseLetter,
                            separator: " ",
                            uppercaseColor: currentLetter.color,
                            lowercaseColor: currentLetter.color.opacity(0.35),
                            font: .system(size: letterSize, weight: .bold, design: .default),
                            minimumScaleFactor: 0.4,
                            horizontalInset: max(4, letterSize * 0.08)
                        )
                        .padding()

                        Text(currentLetter.word)
                            .font(.system(size: wordSize, weight: .bold, design: .default))
                            .foregroundStyle(.black)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .buttonStyle(.borderless)
                .focused($focusedTarget, equals: .hero)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if location.x < geo.size.width * 0.3 {
                        onDetailMove(.left)
                    } else if location.x > geo.size.width * 0.7 {
                        onDetailMove(.right)
                    } else {
                        onSpeak()
                    }
                }
            }
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
