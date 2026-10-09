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
            ZStack {
                currentColour.color.ignoresSafeArea()
                
                Button(action: onSpeak) {
                    Text(currentColour.label)
                        .font(.system(size: min(geo.size.height * 0.21, geo.size.width * 0.18), weight: .bold, design: .default))
                        .foregroundStyle(currentColour.kind.labelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, geo.size.width * 0.08)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .buttonStyle(.borderless)
                .focused($focusedTarget, equals: .hero)
                .focusEffectDisabled()
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
        .environment(\.isFocusEffectEnabled, false)
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
