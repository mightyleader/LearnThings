//
//  GridView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI
import UIKit

struct GridView: View {
    let alphabet: [LetterCard]
    @Binding var selectedIndex: Int
    @Binding var showingGrid: Bool
    @FocusState var focusedTarget: FocusTarget?
    @Binding var isAutoPlayActive: Bool
    var onGridMove: (MoveCommandDirection) -> Void
    var onGridPlayPause: () -> Void
    var onSelectTile: (Int) -> Void

    private let tileFontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geo in
            let hPad = Layout.gridHorizontalPadding
            let vPad = Layout.gridVerticalPadding
            let gap = Layout.gridGap
            let cols = CGFloat(Layout.gridColumns)
            let rows = CGFloat(Int(ceil(Double(alphabet.count) / Double(Layout.gridColumns))))

            let cellWidth  = (geo.size.width  - hPad * 2 - gap * (cols - 1)) / cols
            let cellHeight = (geo.size.height - vPad * 2 - gap * (rows - 1)) / rows
            let fontSize   = cellHeight * Layout.gridLetterScale

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gap), count: Layout.gridColumns),
                spacing: gap
            ) {
                ForEach(Array(alphabet.enumerated()), id: \.element.letter) { index, item in
                    let isFocused = focusedTarget == .tile(item.letter)

                    Button {
                        onSelectTile(index)
                    } label: {
                        LetterPairLabel(
                            uppercase: item.uppercaseLetter,
                            lowercase: item.lowercaseLetter,
                            separator: "",
                            uppercaseColor: UIColor(item.color),
                            lowercaseColor: UIColor(item.color.opacity(0.35)),
                            font: uiFontOrFallback(name: tileFontName, size: fontSize, fallbackWeight: .bold),
                            minimumScaleFactor: 0.8,
                            horizontalInset: max(2, fontSize * 0.08)
                        )
                        .frame(width: cellWidth, height: cellHeight)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.gridTileCornerRadius, style: .continuous)
                                .fill(Color.clear)
                        )
                        .animation(.easeInOut(duration: 0.10), value: isFocused)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedTarget, equals: .tile(item.letter))
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .onMoveCommand(perform: onGridMove)
            .onPlayPauseCommand(perform: onGridPlayPause)
        }
    }

    private func uiFontOrFallback(name: String, size: CGFloat, fallbackWeight: UIFont.Weight) -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: fallbackWeight)
    }
}
