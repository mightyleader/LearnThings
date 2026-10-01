//
//  ColourDetailView.swift
//  Learn Things
//

import SwiftUI

struct ColourDetailView: View {
    let currentColour: ColourCard
    @FocusState var focusedTarget: FocusTarget?
    var onDetailMove: (NavigationDirection) -> Void
    var onDetailPlayPause: () -> Void
    var onExit: () -> Void
    var onSpeak: () -> Void

    var body: some View {
        GeometryReader { geo in
            Button(action: onSpeak) {
                Text(currentColour.label)
                    .font(.custom("AkzidenzGroteskBE-Bold", size: min(geo.size.height * 0.21, geo.size.width * 0.18)))
                    .foregroundStyle(currentColour.kind.labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, geo.size.width * 0.08)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .background(currentColour.color)
            }
            .buttonStyle(.borderless)
            .focused($focusedTarget, equals: .hero)
            .focusEffectDisabled()
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
        .background(currentColour.color.ignoresSafeArea())
        .ignoresSafeArea()
        .environment(\.isFocusEffectEnabled, false)
    }
}