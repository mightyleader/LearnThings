//
//  RandomPromptView.swift
//  Learn Things
//
//  Created by Rob Stearn on 02/10/2026.
//

import SwiftUI

private enum RandomPromptSymbol: Equatable {
    case letter(String)
    case number(Int)
    case shape(ShapeKind)

    static func random() -> Self {
        switch Int.random(in: 0..<3) {
        case 0:
            return .letter(String(UnicodeScalar(Int.random(in: 65...90))!))
        case 1:
            return .number(Int.random(in: 0...10))
        default:
            return .shape(ShapeKind.allCases.randomElement() ?? .circle)
        }
    }
}

private struct RandomPrompt: Equatable {
    let colourKind: ColourKind
    let symbol: RandomPromptSymbol

    var colourLabel: String { colourKind.name }
    var displayColor: Color { LearningPalette.color(forColour: colourKind) }

    var answerText: String {
        switch symbol {
        case .letter(let letter):
            return "\(colourLabel) \(letter.uppercased())"
        case .number(let number):
            return "\(colourLabel) \(number)"
        case .shape(let kind):
            return "\(colourLabel) \(kind.displayName)"
        }
    }

    static func random(excluding previous: RandomPrompt? = nil) -> RandomPrompt {
        var next = generate()
        var attempts = 0

        while next == previous && attempts < 12 {
            next = generate()
            attempts += 1
        }

        return next
    }

    private static func generate() -> RandomPrompt {
        let promptColours = ColourKind.allCases.filter {
            ![.grey, .black, .white].contains($0)
        }

        return RandomPrompt(
            colourKind: promptColours.randomElement() ?? .blue,
            symbol: RandomPromptSymbol.random()
        )
    }
}

struct RandomPromptView: View {
    var onBackToModeSelection: () -> Void

    @State private var prompt = RandomPrompt.random()
    @State private var isAnswerVisible = false
    @FocusState private var isPromptFocused: Bool

    private let fontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geo in
            let canvasWidth = geo.size.width * 0.84
            let canvasHeight = geo.size.height * 0.82
            let answerSize = min(geo.size.height * 0.085, geo.size.width * 0.058)
            let answerHeight = geo.size.height * 0.12

            Button(action: handlePrimaryAction) {
                VStack(spacing: geo.size.height * 0.04) {
                    Spacer(minLength: geo.size.height * 0.03)

                    promptSymbol(in: CGSize(width: canvasWidth, height: canvasHeight))
                    .frame(width: canvasWidth, height: canvasHeight)

                    Text(prompt.answerText)
                        .font(.custom(fontName, size: answerSize))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .padding(.horizontal, geo.size.width * 0.08)
                        .frame(height: answerHeight)
                        .opacity(isAnswerVisible ? 1 : 0)

                    Spacer(minLength: geo.size.height * 0.03)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focused($isPromptFocused)
            .onAppear {
                isPromptFocused = true
            }
            #if os(tvOS)
            .onPlayPauseCommand(perform: handlePrimaryAction)
            .onExitCommand(perform: onBackToModeSelection)
            #endif
        }
        .background(Color.white.ignoresSafeArea())
        .environment(\.isFocusEffectEnabled, false)
    }

    @ViewBuilder
    private func promptSymbol(in size: CGSize) -> some View {
        switch prompt.symbol {
        case .letter(let letter):
            Text(letter.uppercased())
                .font(.custom(fontName, size: min(size.width, size.height) * 0.92))
                .foregroundStyle(prompt.displayColor)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            .frame(width: size.width, height: size.height)
        case .number(let number):
            Text(String(number))
                .font(.custom(fontName, size: min(size.width, size.height) * 0.94))
                .foregroundStyle(prompt.displayColor)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(width: size.width, height: size.height)
        case .shape(let kind):
            ShapeSymbolView(kind: kind, color: prompt.displayColor)
                .frame(width: shapeFrame(for: kind, in: size).width, height: shapeFrame(for: kind, in: size).height)
        }
    }

    private func shapeFrame(for kind: ShapeKind, in size: CGSize) -> CGSize {
        let base = min(size.width, size.height)

        switch kind {
        case .circle:
            return CGSize(width: base * 0.74, height: base * 0.74)
        case .oval:
            return CGSize(width: base * 0.94, height: base * 0.56)
        case .triangle:
            return CGSize(width: base * 0.72, height: base * 0.80)
        case .square:
            return CGSize(width: base * 0.68, height: base * 0.68)
        case .rectangle:
            return CGSize(width: base * 0.96, height: base * 0.58)
        case .diamond:
            return CGSize(width: base * 0.72, height: base * 0.72)
        case .arrow:
            return CGSize(width: base * 0.96, height: base * 0.58)
        case .heart, .star:
            return CGSize(width: base * 0.78, height: base * 0.78)
        case .crescent:
            return CGSize(width: base * 0.80, height: base * 0.80)
        case .cloud, .pentagon, .hexagon, .octagon:
            return CGSize(width: base * 0.82, height: base * 0.82)
        case .rhombus:
            return CGSize(width: base * 0.86, height: base * 0.62)
        }
    }

    private func handlePrimaryAction() {
        if isAnswerVisible {
            prompt = RandomPrompt.random(excluding: prompt)
            isAnswerVisible = false
        } else {
            isAnswerVisible = true
        }
    }
}

#Preview {
    RandomPromptView(onBackToModeSelection: {})
}
