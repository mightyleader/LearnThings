//
//  ModeSelectionView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var selectedMode: AppMode?
    var onOpenVoiceSettings: () -> Void = {}
    @FocusState private var focusedButton: ModeButton?

    private let buttonFontName = "AkzidenzGroteskBE-Bold"
    private let subtitleFontName = "AkzidenzGroteskBE-Bold"
    private let cardCornerRadius: CGFloat = 18

    enum ModeButton {
        case letters
        case numbers
        case shapes
        case voice
    }

    private struct Token: Identifiable {
        let id = UUID()
        let text: String
        let color: Color
    }
    
    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * 0.26
            let cardHeight = geo.size.height * 0.32
            let voiceWidth = geo.size.width * 0.26
            let voiceHeight = geo.size.height * 0.08
            let topLineSize = geo.size.height * 0.12
            let subtitleSize = geo.size.height * 0.055
            let focusBlue = Color(red: 0.87, green: 0.94, blue: 1.0)
            let buttonBase = Color.white

            VStack(spacing: 0) {
                Spacer(minLength: geo.size.height * 0.18)

                HStack(spacing: geo.size.width * 0.035) {
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
                    makeModeCard(
                        mode: .shapes,
                        tokens: tokenLine(texts: ["●", "▲", "■"], colors: Array(ShapeCard.samples.prefix(3).map(\.color))),
                        subtitle: "shapes",
                        width: cardWidth,
                        height: cardHeight,
                        topLineSize: topLineSize,
                        subtitleSize: subtitleSize
                    )
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: geo.size.height * 0.14)

                Button(action: onOpenVoiceSettings) {
                    Text("voices")
                        .font(.custom(subtitleFontName, size: geo.size.height * 0.045))
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

                Spacer(minLength: geo.size.height * 0.06)
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
                    } else if focusedButton == .shapes {
                        focusedButton = .numbers
                    }
                case .right:
                    if focusedButton == .letters {
                        focusedButton = .numbers
                    } else if focusedButton == .numbers {
                        focusedButton = .shapes
                    }
                case .up:
                    if focusedButton == .voice {
                        focusedButton = .numbers
                    }
                case .down:
                    if focusedButton == .letters || focusedButton == .numbers || focusedButton == .shapes {
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
        }
    }
}

enum AppMode {
    case letters
    case numbers
    case shapes
}

#Preview {
    ModeSelectionView(selectedMode: .constant(nil))
}
