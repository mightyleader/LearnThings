//
//  ShapeGridView.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/09/2026.
//

import SwiftUI

struct ShapeGridView: View {
    let shapes: [ShapeCard]
    @FocusState var focusedTarget: FocusTarget?
    var onBackToModeSelection: () -> Void
    var onGridMove: (NavigationDirection) -> Void
    var onGridPlayPause: () -> Void
    var onSelectTile: (Int) -> Void

    private let columns = 4
    private let labelFontName = "AkzidenzGroteskBE-Bold"
    private let focusColor = Color(red: 0.87, green: 0.94, blue: 1.0)

    var body: some View {
        GeometryReader { geo in
            let outerTopPadding = geo.size.height * 0.02
            let outerBottomPadding = geo.size.height * 0.02
            let contentHeight = geo.size.height - outerTopPadding - outerBottomPadding

            VStack(spacing: 0) {
                let hPad = AppLayout.gridHorizontalPadding
                let vPad = AppLayout.gridVerticalPadding * 0.15
                let gap = AppLayout.gridGap * 1.8
                let cols = CGFloat(columns)
                let rows = CGFloat(Int(ceil(Double(shapes.count) / Double(columns))))
                let cellWidth = (geo.size.width - hPad * 2 - gap * (cols - 1)) / cols
                let cellHeight = (contentHeight - vPad * 2 - gap * (rows - 1)) / rows
                let labelSize = min(cellHeight * 0.20, cellWidth * 0.105)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gap), count: columns),
                    spacing: gap
                ) {
                    ForEach(Array(shapes.enumerated()), id: \.element.id) { index, item in
                        let isFocused = focusedTarget == .tile(item.id)
                        let symbolSize = symbolFrame(for: item.kind, in: CGSize(width: cellWidth, height: cellHeight))

                        Button {
                            onSelectTile(index)
                        } label: {
                            VStack(spacing: cellHeight * 0.10) {
                                ShapeSymbolView(kind: item.kind, color: item.color)
                                    .frame(width: symbolSize.width, height: symbolSize.height)

                                Text(item.label)
                                    .font(.custom(labelFontName, size: labelSize))
                                    .foregroundStyle(.black)
                                    .lineLimit(1)
                            }
                            .frame(width: cellWidth, height: cellHeight)
                            .background(
                                RoundedRectangle(cornerRadius: AppLayout.gridTileCornerRadius, style: .continuous)
                                    .fill(isFocused ? focusColor : Color.clear)
                            )
                        }
                        .buttonStyle(.borderless)
                        .focused($focusedTarget, equals: .tile(item.id))
                        .focusEffectDisabled()
                    }
                }
                .frame(height: contentHeight)
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .padding(.top, outerTopPadding)
            .padding(.bottom, outerBottomPadding)
            .background(Color.white)
            .environment(\.isFocusEffectEnabled, false)
            #if os(tvOS)
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
            #endif
        }
        .focusEffectDisabled(true)
    }

    private func symbolFrame(for kind: ShapeKind, in cell: CGSize) -> CGSize {
        let base = min(cell.width, cell.height)

        switch kind {
        case .circle:
            return CGSize(width: base * 0.72, height: base * 0.72)
        case .oval:
            return CGSize(width: base * 0.88, height: base * 0.50)
        case .triangle:
            return CGSize(width: base * 0.68, height: base * 0.74)
        case .square:
            return CGSize(width: base * 0.64, height: base * 0.64)
        case .rectangle:
            return CGSize(width: base * 0.84, height: base * 0.52)
        case .diamond:
            return CGSize(width: base * 0.68, height: base * 0.68)
        case .arrow:
            return CGSize(width: base * 0.84, height: base * 0.56)
        case .heart, .star:
            return CGSize(width: base * 0.72, height: base * 0.72)
        case .crescent:
            return CGSize(width: base * 0.74, height: base * 0.74)
        case .cloud, .pentagon, .hexagon, .octagon:
            return CGSize(width: base * 0.74, height: base * 0.74)
        case .rhombus:
            return CGSize(width: base * 0.74, height: base * 0.54)
        }
    }
}
