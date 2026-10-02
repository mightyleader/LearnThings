//
//  ModeSelectionView.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var selectedMode: AppMode?
    @Binding var voicesEnabled: Bool
    var onOpenVoiceSettings: () -> Void = {}
    @FocusState private var focusedButton: ModeButton?
    @State private var lastFocusedBottomMode: ModeButton = .shapes

    private let buttonFontName = "AkzidenzGroteskBE-Bold"
    private let subtitleFontName = "AkzidenzGroteskBE-Bold"
    private let cardCornerRadius: CGFloat = 18

    enum ModeButton {
        case letters
        case numbers
        case shapes
        case colours
        case random
        case voice
    }

    private struct Token {
        let text: String
        let color: Color
    }
    
    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * 0.36
            let cardHeight = geo.size.height * 0.24
            let voiceWidth = geo.size.width * 0.30
            let voiceHeight = geo.size.height * 0.09
            let topLineSize = cardHeight * 0.40
            let subtitleSize = cardHeight * 0.20
            let focusBlue = Color(red: 0.87, green: 0.94, blue: 1.0)
            let buttonBase = Color.white

            VStack(spacing: geo.size.height * 0.018) {
                Spacer(minLength: geo.size.height * 0.035)

                HStack(spacing: geo.size.width * 0.04) {
                    makeModeCard(
                        mode: .letters,
                        tokens: tokenLine(texts: ["A", "B", "C"], colors: Array(LetterCard.samples.prefix(3).map(\.color))),
                        subtitle: "letters",
                        width: cardWidth,
                        height: cardHeight,
                        topLineSize: topLineSize,
                        subtitleSize: subtitleSize
                    )

                    makeModeCard(
                        mode: .numbers,
                        tokens: tokenLine(texts: ["1", "2", "3"], colors: Array(NumberCard.samples.prefix(3).map(\.color))),
                        subtitle: "numbers",
                        width: cardWidth,
                        height: cardHeight,
                        topLineSize: topLineSize,
                        subtitleSize: subtitleSize
                    )
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: geo.size.width * 0.04) {
                    makeModeCard(
                        mode: .shapes,
                        tokens: tokenLine(texts: ["★", "▲", "■"], colors: Array(ShapeCard.samples.prefix(3).map(\.color))),
                        subtitle: "shapes",
                        width: cardWidth,
                        height: cardHeight,
                        topLineSize: topLineSize,
                        subtitleSize: subtitleSize
                    )
                    makeModeCard(
                        mode: .colours,
                        tokens: tokenLine(texts: ["■", "■", "■"], colors: Array(ColourCard.samples.prefix(3).map(\.color))),
                        subtitle: "colours",
                        width: cardWidth,
                        height: cardHeight,
                        topLineSize: topLineSize,
                        subtitleSize: subtitleSize
                    )
                }
                .frame(maxWidth: .infinity)

                HStack {
                    makeModeCard(
                        mode: .random,
                        tokens: tokenLine(
                            texts: ["A", "7", "★"],
                            colors: [
                                LearningPalette.color(forLetter: "A"),
                                LearningPalette.color(forNumber: 7),
                                LearningPalette.color(forShape: .star)
                            ]
                        ),
                        subtitle: "random",
                        width: cardWidth,
                        height: cardHeight,
                        topLineSize: topLineSize,
                        subtitleSize: subtitleSize
                    )
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: geo.size.height * 0.02)

                HStack(spacing: geo.size.width * 0.03) {
                    Button(action: onOpenVoiceSettings) {
                        HStack(spacing: geo.size.width * 0.012) {
                            Text("voices")
                            if !voicesEnabled {
                                Text("off")
                                    .font(.custom(buttonFontName, size: geo.size.height * 0.027))
                                    .padding(.horizontal, geo.size.width * 0.022)
                                    .padding(.vertical, geo.size.height * 0.006)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color(red: 0.94, green: 0.64, blue: 0.64))
                                    )
                                    .foregroundStyle(Color(red: 0.32, green: 0.08, blue: 0.08))
                            }
                        }
                        .font(.custom(subtitleFontName, size: geo.size.height * 0.05))
                        .foregroundStyle(Color(red: 0.18, green: 0.22, blue: 0.32))
                        .frame(width: voiceWidth, height: voiceHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(focusedButton == .voice ? focusBlue : buttonBase)
                        )
                        .scaleEffect(focusedButton == .voice ? 1.04 : 1.0)
                    }
                    .buttonStyle(.borderless)
                    .focused($focusedButton, equals: .voice)
                    .focusEffectDisabled(true)
                }

                Spacer(minLength: geo.size.height * 0.035)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.white)
            .environment(\.isFocusEffectEnabled, false)
            .onAppear {
                if focusedButton == nil {
                    focusedButton = .letters
                }
            }
            #if os(tvOS)
            .onMoveCommand { direction in
                switch direction {
                case .left:
                    if focusedButton == .numbers {
                        focusedButton = .letters
                    } else if focusedButton == .colours {
                        focusedButton = .shapes
                    }
                case .right:
                    if focusedButton == .letters {
                        focusedButton = .numbers
                    } else if focusedButton == .shapes {
                        focusedButton = .colours
                    }
                case .up:
                    if focusedButton == .voice {
                        focusedButton = .random
                    } else if focusedButton == .random {
                        focusedButton = lastFocusedBottomMode
                    } else if focusedButton == .shapes {
                        focusedButton = .letters
                    } else if focusedButton == .colours {
                        focusedButton = .numbers
                    }
                case .down:
                    if focusedButton == .letters {
                        focusedButton = .shapes
                    } else if focusedButton == .numbers {
                        focusedButton = .colours
                    } else if focusedButton == .shapes || focusedButton == .colours {
                        lastFocusedBottomMode = focusedButton ?? .shapes
                        focusedButton = .random
                    } else if focusedButton == .random {
                        focusedButton = .voice
                    }
                default:
                    break
                }
            }
            #endif
        }
        .focusEffectDisabled(true)
    }
    
    private func tokenLine(texts: [String], colors: [Color]) -> [Token] {
        zip(texts, colors).map { Token(text: $0.0, color: $0.1) }
    }

    private func makeModeCard(
        mode: AppMode,
        tokens: [Token],
        subtitle: String,
        width: CGFloat,
        height: CGFloat,
        topLineSize: CGFloat,
        subtitleSize: CGFloat
    ) -> some View {
        Button(action: {
            selectedMode = mode
        }) {
            VStack(spacing: height * 0.08) {
                HStack(spacing: 0) {
                    ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                        Text(token.text)
                            .font(.custom(buttonFontName, size: topLineSize))
                            .foregroundStyle(token.color)
                            .tracking(index == tokens.count - 1 ? 0 : -2)
                    }
                }

                Text(subtitle)
                    .font(.custom(subtitleFontName, size: subtitleSize))
                    .foregroundStyle(.black)
                    .textCase(.lowercase)
            }
            .frame(width: width, height: height)
            .padding(.horizontal, width * 0.05)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius + 10, style: .continuous)
                    .fill(focusedButton == modeFocus(mode) ? Color(red: 0.87, green: 0.94, blue: 1.0) : Color.white)
            )
            .scaleEffect(focusedButton == modeFocus(mode) ? 1.04 : 1.0)
        }
        .buttonStyle(.borderless)
        .focused($focusedButton, equals: modeFocus(mode))
        .focusEffectDisabled(true)
    }

    private func modeFocus(_ mode: AppMode) -> ModeButton {
        switch mode {
        case .letters:
            return .letters
        case .numbers:
            return .numbers
        case .shapes:
            return .shapes
        case .colours:
            return .colours
        case .random:
            return .random
        }
    }
}

enum AppMode {
    case letters
    case numbers
    case shapes
    case colours
    case random
}

#Preview {
    ModeSelectionView(selectedMode: .constant(nil), voicesEnabled: .constant(true))
}
