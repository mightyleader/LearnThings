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

    private let cardCornerRadius: CGFloat = 22
    private let buttonBase = Color(red: 0.97, green: 0.98, blue: 1.0)
    private let buttonBorder = Color(red: 0.88, green: 0.90, blue: 0.94)
    private let inkColor = Color(red: 0.18, green: 0.22, blue: 0.32)

    enum ModeButton {
        case letters
        case numbers
        case shapes
        case colours
        case random
        case voice
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * 0.29
            let cardHeight = geo.size.height * 0.16
            let voiceWidth = geo.size.width * 0.25
            let voiceHeight = geo.size.height * 0.08
            let subtitleSize = cardHeight * 0.20

            VStack(spacing: geo.size.height * 0.035) {
                Spacer(minLength: geo.size.height * 0.035)

                HStack(spacing: geo.size.width * 0.12) {
                    makeModeCard(
                        mode: .letters,
                        subtitle: "letters",
                        width: cardWidth,
                        height: cardHeight,
                        subtitleSize: subtitleSize
                    )

                    makeModeCard(
                        mode: .numbers,
                        subtitle: "numbers",
                        width: cardWidth,
                        height: cardHeight,
                        subtitleSize: subtitleSize
                    )
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: geo.size.width * 0.12) {
                    makeModeCard(
                        mode: .shapes,
                        subtitle: "shapes",
                        width: cardWidth,
                        height: cardHeight,
                        subtitleSize: subtitleSize
                    )
                    makeModeCard(
                        mode: .colours,
                        subtitle: "colours",
                        width: cardWidth,
                        height: cardHeight,
                        subtitleSize: subtitleSize
                    )
                }
                .frame(maxWidth: .infinity)

                HStack {
                    makeModeCard(
                        mode: .random,
                        subtitle: "random",
                        width: cardWidth,
                        height: cardHeight,
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
                                    .font(.system(size: geo.size.height * 0.027, weight: .semibold, design: .default))
                                    .padding(.horizontal, geo.size.width * 0.022)
                                    .padding(.vertical, geo.size.height * 0.006)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color(red: 0.94, green: 0.64, blue: 0.64))
                                    )
                                    .foregroundStyle(Color(red: 0.32, green: 0.08, blue: 0.08))
                            }
                        }
                        .font(.system(size: geo.size.height * 0.05, weight: .semibold, design: .default))
                        .foregroundStyle(inkColor)
                        .frame(width: voiceWidth, height: voiceHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(buttonBase)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(buttonBorder, lineWidth: 1)
                        }
                    }
                    .focused($focusedButton, equals: .voice)
                }

                Spacer(minLength: geo.size.height * 0.035)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.white)
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
    }
    
    private func makeModeCard(
        mode: AppMode,
        subtitle: String,
        width: CGFloat,
        height: CGFloat,
        subtitleSize: CGFloat
    ) -> some View {
        return Button(action: {
            selectedMode = mode
        }) {
            VStack(spacing: height * 0.08) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: height * 0.42, weight: .semibold))
                    .foregroundStyle(inkColor)

                Text(subtitle)
                    .font(.system(size: subtitleSize, weight: .semibold, design: .default))
                    .foregroundStyle(inkColor)
                    .textCase(.lowercase)
            }
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius + 10, style: .continuous)
                    .fill(buttonBase)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cardCornerRadius + 10, style: .continuous)
                    .strokeBorder(buttonBorder, lineWidth: 1)
            }
        }
        .focused($focusedButton, equals: modeFocus(mode))
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

enum AppMode: String, CaseIterable, Identifiable, Hashable {
    case letters
    case numbers
    case shapes
    case colours
    case random

    var id: Self { self }

    var title: String {
        switch self {
        case .letters: return "Letters"
        case .numbers: return "Numbers"
        case .shapes: return "Shapes"
        case .colours: return "Colours"
        case .random: return "Random"
        }
    }

    var systemImage: String {
        switch self {
        case .letters: return "textformat.alt"
        case .numbers: return "textformat.numbers"
        case .shapes: return "square.on.circle"
        case .colours: return "rainbow"
        case .random: return "shuffle"
        }
    }
}

#Preview {
    ModeSelectionView(selectedMode: .constant(nil), voicesEnabled: .constant(true))
}
