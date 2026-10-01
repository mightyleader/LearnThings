//
//  GridView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct GridView: View {
    let alphabet: [LetterCard]
    @Binding var selectedIndex: Int
    @Binding var showingGrid: Bool
    @FocusState var focusedTarget: FocusTarget?
    @Binding var isAutoPlayActive: Bool
    var onBackToModeSelection: () -> Void
    var onGridMove: (NavigationDirection) -> Void
    var onGridPlayPause: () -> Void
    var onSelectTile: (Int) -> Void

    private let tileFontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geo in
            let hPad = AppLayout.gridHorizontalPadding
            let vPad = AppLayout.gridVerticalPadding
            let gap = AppLayout.gridGap
            let cols = CGFloat(AppLayout.gridColumns)
            let rows = CGFloat(Int(ceil(Double(alphabet.count) / Double(AppLayout.gridColumns))))

            let cellWidth  = (geo.size.width  - hPad * 2 - gap * (cols - 1)) / cols
            let cellHeight = (geo.size.height - vPad * 2 - gap * (rows - 1)) / rows
            let fontSize   = cellHeight * AppLayout.gridLetterScale

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gap), count: AppLayout.gridColumns),
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
                            uppercaseColor: item.color,
                            lowercaseColor: item.color.opacity(0.35),
                            font: .custom(tileFontName, size: fontSize),
                            minimumScaleFactor: 0.8,
                            horizontalInset: max(2, fontSize * 0.08)
                        )
                        .frame(width: cellWidth, height: cellHeight)
                        .background(
                            RoundedRectangle(cornerRadius: AppLayout.gridTileCornerRadius, style: .continuous)
                                .fill(isFocused ? Color(red: 0.87, green: 0.94, blue: 1.0) : Color.clear)
                        )
                    }
                    .buttonStyle(.borderless)
                    .focused($focusedTarget, equals: .tile(item.letter))
                    .focusEffectDisabled()
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .environment(\.isFocusEffectEnabled, false)
            .onMoveCommand { direction in
                switch direction {
                case .up: onGridMove(.up)
                case .down: onGridMove(.down)
                case .left: onGridMove(.left)
                case .right: onGridMove(.right)
                @unknown default: break
                }
            }
            .onPlayPauseCommand(perform: onGridPlayPause)
            .onExitCommand(perform: onBackToModeSelection)
        }
    }

}
