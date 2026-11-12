//
//  DetailView.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct DetailView: View {
    let currentLetter: LetterCard
    @Environment(\.colorScheme) private var colorScheme
    @FocusState var focusedTarget: FocusTarget?
    var autoPlayStartedAt: Date?
    var autoPlayInterval: TimeInterval
    var onDetailMove: (NavigationDirection) -> Void
    var onDetailPlayPause: () -> Void
    var onExit: () -> Void
    var onSpeak: () -> Void

    var body: some View {
        GeometryReader { geo in
            let letterSize = geo.size.height * AppLayout.detailLetterHeightRatio
            let wordSize   = geo.size.height * AppLayout.detailWordHeightRatio

            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                Button(action: onSpeak) {
                    VStack(spacing: geo.size.height * AppLayout.detailVStackSpacingRatio) {
                        LetterPairLabel(
                            uppercase: currentLetter.uppercaseLetter,
                            lowercase: currentLetter.lowercaseLetter,
                            separator: " ",
                            uppercaseColor: currentLetter.color.adaptedForDarkMode(colorScheme),
                            lowercaseColor: currentLetter.color.adaptedForDarkMode(colorScheme).opacity(0.35),
                            font: .system(size: letterSize, weight: .bold, design: .rounded),
                            minimumScaleFactor: 0.4,
                            horizontalInset: max(4, letterSize * 0.08)
                        )
                        .padding()

                        Text(currentLetter.word)
                            .font(.system(size: wordSize, weight: .bold, design: .default))
                            .foregroundStyle(.primary)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .buttonStyle(.borderless)
                .focused($focusedTarget, equals: .hero)
                .contentShape(Rectangle())

                #if os(iOS)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                handleTap(at: value.location, width: geo.size.width)
                            }
                    )
                #endif

                if let autoPlayStartedAt {
                    AutoPlayProgressIndicator(startDate: autoPlayStartedAt, duration: autoPlayInterval)
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
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

    private func handleTap(at location: CGPoint, width: CGFloat) {
        if location.x < width * 0.3 {
            onDetailMove(.left)
        } else if location.x > width * 0.7 {
            onDetailMove(.right)
        } else {
            onSpeak()
        }
    }

}

struct AutoPlayProgressIndicator: View {
    let startDate: Date
    let duration: TimeInterval
    var size: CGFloat = 34

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let remaining = max(0, 1 - elapsed / duration)

            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.25), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: remaining)
                    .stroke(.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: size, height: size)
            .accessibilityLabel("Time until next item")
            .accessibilityValue("\(Int(remaining * duration)) seconds")
        }
        .allowsHitTesting(false)
    }
}
