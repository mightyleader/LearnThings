//
//  NumberDetailView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct NumberDetailView: View {
    let currentNumber: NumberCard
    @FocusState var focusedTarget: FocusTarget?
    var onDetailMove: (NavigationDirection) -> Void
    var onDetailPlayPause: () -> Void
    var onExit: () -> Void
    var onSpeak: () -> Void

    private let numberFontName = "AkzidenzGroteskBE-Bold"
    private let wordFontName = "AkzidenzGroteskBE-Bold"
    private let numberHeightRatio: CGFloat = 0.50
    private let wordHeightRatio: CGFloat = 0.15
    private let vStackSpacingRatio: CGFloat = 0.05
    private let dotsAreaHeight: CGFloat = 92

    var body: some View {
        GeometryReader { geo in
            let numberSize = geo.size.height * numberHeightRatio
            let wordSize   = geo.size.height * wordHeightRatio
            let topInset   = geo.size.height * 0.08

            Button(action: onSpeak) {
                VStack(alignment: .center, spacing: geo.size.height * vStackSpacingRatio) {
                    Text(currentNumber.displayNumber)
                        .font(.custom(numberFontName, size: numberSize))
                        .foregroundStyle(currentNumber.color)
                        .padding()

                    Text(currentNumber.word)
                        .font(.custom(wordFontName, size: wordSize))
                        .foregroundStyle(.black)
                    
                    dotsForNumber(currentNumber.number)
                        .frame(height: dotsAreaHeight, alignment: .top)
                    Spacer()
                }
                .padding(.top, topInset)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
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
    
    private func dotsForNumber(_ number: Int) -> some View {
        // Handle zero case - return empty view
        if number == 0 {
            return AnyView(EmptyView())
        }
        
        let dotsPerRow: Int
        if number <= 5 {
            dotsPerRow = number
        } else {
            dotsPerRow = 5
        }
        
        let rows = (number + dotsPerRow - 1) / dotsPerRow
        let dotSize: CGFloat = 50
        
        return AnyView(
            VStack(spacing: 16) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 16) {
                        Spacer()
                        ForEach(0..<dotsPerRow, id: \.self) { col in
                            if row * dotsPerRow + col < number {
                                Circle()
                                    .fill(Color(white: 0.5))
                                    .frame(width: dotSize, height: dotSize)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
        )
    }

}
