//
//  NumberGridView.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct NumberGridView: View {
    let numbers: [NumberCard]
    @FocusState var focusedTarget: FocusTarget?
    var onBackToModeSelection: () -> Void
    var onGridMove: (NavigationDirection) -> Void
    var onGridPlayPause: () -> Void
    var onSelectTile: (Int) -> Void

    private let numberFontName = "AkzidenzGroteskBE-Bold"
    private let finalTileExtraWidthFactor: CGFloat = 0.5

    private var rowSlices: [ArraySlice<NumberCard>] {
        stride(from: 0, to: numbers.count, by: AppLayout.gridColumns).map { start in
            let end = min(start + AppLayout.gridColumns, numbers.count)
            return numbers[start..<end]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let hPad = AppLayout.gridHorizontalPadding
            let vPad = AppLayout.gridVerticalPadding
            let gap = AppLayout.gridGap
            let cols = CGFloat(AppLayout.gridColumns)
            let rows = CGFloat(rowSlices.count)

            let cellWidth = (geo.size.width - hPad * 2 - gap * (cols - 1)) / cols
            let cellHeight = (geo.size.height - vPad * 2 - gap * (rows - 1)) / rows
            let fontSize   = cellHeight * AppLayout.gridLetterScale

            VStack(spacing: gap) {
                ForEach(Array(rowSlices.enumerated()), id: \.offset) { rowIndex, rowItems in
                    let trailingEmptyColumns = max(0, AppLayout.gridColumns - rowItems.count)

                    HStack(spacing: gap) {
                        ForEach(Array(rowItems.enumerated()), id: \.element.id) { columnIndex, item in
                            let globalIndex = (rowIndex * AppLayout.gridColumns) + columnIndex
                            let isFocused = focusedTarget == .tile(item.id)
                            let isTrailingExpandedItem = trailingEmptyColumns > 0 && columnIndex == rowItems.count - 1
                            let extraTrailingWidth = isTrailingExpandedItem
                                ? CGFloat(trailingEmptyColumns) * (cellWidth + gap) * finalTileExtraWidthFactor
                                : 0
                            let tileWidth = isTrailingExpandedItem
                                ? cellWidth + extraTrailingWidth
                                : cellWidth

                            Button {
                                onSelectTile(globalIndex)
                            } label: {
                                Text(item.displayNumber)
                                    .font(.custom(numberFontName, size: fontSize))
                                    .foregroundStyle(item.color)
                                    .tracking(item.number == 10 ? -1 : 0)
                                    .frame(width: tileWidth, height: cellHeight, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppLayout.gridTileCornerRadius, style: .continuous)
                                            .fill(isFocused ? Color(red: 0.87, green: 0.94, blue: 1.0) : Color.clear)
                                    )
                            }
                            .buttonStyle(.borderless)
                            .focused($focusedTarget, equals: .tile(item.id))
                            .focusEffectDisabled()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .focusEffectDisabled(true)
    }
}
