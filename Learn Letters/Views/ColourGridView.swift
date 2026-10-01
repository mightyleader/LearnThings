//
//  ColourGridView.swift
//  Learn Letters
//

import SwiftUI

struct ColourGridView: View {
    let colours: [ColourCard]
    @FocusState var focusedTarget: FocusTarget?
    var onBackToModeSelection: () -> Void
    var onGridMove: (NavigationDirection) -> Void
    var onGridPlayPause: () -> Void
    var onSelectTile: (Int) -> Void

    private let columns = 4
    private let focusBlue = Color(red: 0.87, green: 0.94, blue: 1.0)

    var body: some View {
        GeometryReader { geo in
            let hPad = AppLayout.gridHorizontalPadding
            let vPad = AppLayout.gridVerticalPadding * 0.65
            let gap = AppLayout.gridGap * 2
            let rows = CGFloat((colours.count + columns - 1) / columns)
            let cellWidth = (geo.size.width - 2 * hPad - CGFloat(columns - 1) * gap) / CGFloat(columns)
            let cellHeight = (geo.size.height - 2 * vPad - (rows - 1) * gap) / rows
            let squareSide = min(cellWidth * 0.64, cellHeight * 0.62)
            let labelSize = min(cellHeight * 0.19, cellWidth * 0.115)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gap), count: columns), spacing: gap) {
                ForEach(Array(colours.enumerated()), id: \.element.id) { index, item in
                    let isFocused = focusedTarget == .tile(item.id)

                    Button {
                        onSelectTile(index)
                    } label: {
                        VStack(spacing: cellHeight * 0.08) {
                            Rectangle()
                                .fill(item.color)
                                .overlay {
                                    if item.kind == .white {
                                        Rectangle().strokeBorder(Color(white: 0.72), lineWidth: 2)
                                    }
                                }
                                .frame(width: squareSide, height: squareSide)

                            Text(item.label)
                                .font(.custom("AkzidenzGroteskBE-Bold", size: labelSize))
                                .foregroundStyle(.black)
                                .lineLimit(1)
                        }
                        .frame(width: cellWidth, height: cellHeight)
                        .background(
                            RoundedRectangle(cornerRadius: AppLayout.gridTileCornerRadius, style: .continuous)
                                .fill(isFocused ? focusBlue : .clear)
                        )
                    }
                    .buttonStyle(.borderless)
                    .focused($focusedTarget, equals: .tile(item.id))
                    .focusEffectDisabled()
                }
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.white)
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