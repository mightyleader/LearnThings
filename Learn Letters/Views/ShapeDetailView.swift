//
//  ShapeDetailView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/09/2026.
//

import SwiftUI

struct ShapeDetailView: View {
    let currentShape: ShapeCard
    @FocusState var focusedTarget: FocusTarget?
    var onDetailMove: (NavigationDirection) -> Void
    var onDetailPlayPause: () -> Void
    var onExit: () -> Void
    var onSpeak: () -> Void

    private let wordFontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.size.height * 0.06
            let bottomInset = geo.size.height * 0.06
            let wordSize = geo.size.height * 0.14
            let symbolSize = symbolFrame(for: currentShape.kind, in: geo.size)

            Button(action: onSpeak) {
                ShapeSymbolView(kind: currentShape.kind, color: currentShape.color)
                    .frame(width: symbolSize.width, height: symbolSize.height)
                    .padding(.top, topInset)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .overlay(alignment: .bottom) {
                        Text(currentShape.label)
                            .font(.custom(wordFontName, size: wordSize))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, geo.size.width * 0.05)
                            .padding(.bottom, bottomInset)
                    }
            }
            .buttonStyle(.borderless)
            .focused($focusedTarget, equals: .hero)
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
            .onAppear(perform: onSpeak)
        }
    }

    private func symbolFrame(for kind: ShapeKind, in size: CGSize) -> CGSize {
        let base = min(size.width, size.height)

        switch kind {
        case .circle:
            return CGSize(width: base * 0.56, height: base * 0.56)
        case .oval:
            return CGSize(width: base * 0.72, height: base * 0.42)
        case .triangle:
            return CGSize(width: base * 0.54, height: base * 0.60)
        case .square:
            return CGSize(width: base * 0.48, height: base * 0.48)
        case .rectangle:
            return CGSize(width: base * 0.70, height: base * 0.42)
        case .diamond:
            return CGSize(width: base * 0.52, height: base * 0.52)
        case .arrow:
            return CGSize(width: base * 0.72, height: base * 0.44)
        case .heart, .star:
            return CGSize(width: base * 0.58, height: base * 0.58)
        case .crescent:
            return CGSize(width: base * 0.60, height: base * 0.60)
        case .cloud, .pentagon, .hexagon, .octagon:
            return CGSize(width: base * 0.60, height: base * 0.60)
        case .rhombus:
            return CGSize(width: base * 0.60, height: base * 0.42)
        }
    }
}
