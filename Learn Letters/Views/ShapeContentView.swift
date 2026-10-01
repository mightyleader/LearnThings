//
//  ShapeContentView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/09/2026.
//

import SwiftUI

struct ShapeContentView: View {
    @ObservedObject var speaker: LetterSpeaker
    var onBackToModeSelection: () -> Void

    @State private var selectedIndex = 0
    @State private var showingGrid = true
    @FocusState private var focusedTarget: FocusTarget?
    @State private var isAutoPlayActive = false
    @State private var autoPlayTimer: Timer?

    private let shapes = ShapeCard.samples
    private let columns = 4
    private let gridDwellTime: TimeInterval = 1.0
    private let detailDwellTime: TimeInterval = 3.0

    private var currentShape: ShapeCard {
        shapes[selectedIndex]
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showingGrid {
                ShapeGridView(
                    shapes: shapes,
                    selectedIndex: $selectedIndex,
                    showingGrid: $showingGrid,
                    focusedTarget: _focusedTarget,
                    isAutoPlayActive: $isAutoPlayActive,
                    onBackToModeSelection: onBackToModeSelection,
                    onGridMove: handleGridMove,
                    onGridPlayPause: handleGridPlayPause,
                    onSelectTile: handleSelectTile
                )
            } else {
                ShapeDetailView(
                    currentShape: currentShape,
                    focusedTarget: _focusedTarget,
                    onBackToModeSelection: onBackToModeSelection,
                    onDetailMove: handleHeroMove,
                    onDetailPlayPause: handleDetailPlayPause,
                    onExit: handleExitToGrid,
                    onSpeak: { speaker.speak(phraseFor: currentShape) }
                )
            }
        }
        .onAppear {
            focusedTarget = .tile(shapes[selectedIndex].id)
            speaker.speak(shapeFor: shapes[selectedIndex])
        }
        .onDisappear {
            stopAutoPlay()
        }
        .onChange(of: selectedIndex) { _, newValue in
            if showingGrid {
                speaker.speak(shapeFor: shapes[newValue])
            } else {
                speaker.speak(phraseFor: shapes[newValue])
            }
        }
        .onChange(of: showingGrid) { _, _ in
            stopAutoPlay()
        }
    }

    private func handleHeroMove(_ direction: NavigationDirection) {
        stopAutoPlay()
        switch direction {
        case .left:
            previousShape()
        case .right:
            nextShape()
        case .up, .down:
            break
        }
    }

    private func handleSelectTile(_ index: Int) {
        stopAutoPlay()
        selectedIndex = index
        showingGrid = false
        focusedTarget = .hero
    }

    private func handleExitToGrid() {
        showingGrid = true
        DispatchQueue.main.async {
            focusedTarget = .tile(currentShape.id)
        }
    }

    private func previousShape() {
        selectedIndex = (selectedIndex - 1 + shapes.count) % shapes.count
    }

    private func nextShape() {
        selectedIndex = (selectedIndex + 1) % shapes.count
    }

    private func handleGridPlayPause() {
        if isAutoPlayActive {
            stopAutoPlay()
        } else {
            startAutoPlayGrid()
        }
    }

    private func handleDetailPlayPause() {
        if isAutoPlayActive {
            stopAutoPlay()
        } else {
            startAutoPlayDetail()
        }
    }

    private func startAutoPlayGrid() {
        isAutoPlayActive = true
        scheduleNextGridShape()
    }

    private func startAutoPlayDetail() {
        isAutoPlayActive = true
        scheduleNextDetailShape()
    }

    private func scheduleNextGridShape() {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: gridDwellTime, repeats: false) { _ in
            if isAutoPlayActive {
                nextShape()
                focusedTarget = .tile(shapes[selectedIndex].id)
                scheduleNextGridShape()
            }
        }
    }

    private func scheduleNextDetailShape() {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: detailDwellTime, repeats: false) { _ in
            if isAutoPlayActive {
                nextShape()
                scheduleNextDetailShape()
            }
        }
    }

    private func stopAutoPlay() {
        isAutoPlayActive = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }

    private func handleGridMove(_ direction: NavigationDirection) {
        stopAutoPlay()
        guard !shapes.isEmpty else { return }

        let count = shapes.count
        let lastIndex = count - 1
        let currentIndex = selectedIndex
        let row = currentIndex / columns
        let col = currentIndex % columns
        let totalRows = Int(ceil(Double(count) / Double(columns)))

        func hasCell(row: Int, col: Int) -> Bool {
            let idx = row * columns + col
            return idx >= 0 && idx < count
        }

        func nextValidRowDown(from startRow: Int, col: Int) -> Int {
            for step in 1...totalRows {
                let candidate = (startRow + step) % totalRows
                if hasCell(row: candidate, col: col) { return candidate }
            }
            return startRow
        }

        func nextValidRowUp(from startRow: Int, col: Int) -> Int {
            for step in 1...totalRows {
                let candidate = (startRow - step + totalRows) % totalRows
                if hasCell(row: candidate, col: col) { return candidate }
            }
            return startRow
        }

        let target: Int

        switch direction {
        case .left:
            target = (currentIndex == 0) ? lastIndex : (currentIndex - 1)
        case .right:
            target = (currentIndex == lastIndex) ? 0 : (currentIndex + 1)
        case .up:
            let targetRow = nextValidRowUp(from: row, col: col)
            target = (targetRow * columns) + col
        case .down:
            let targetRow = nextValidRowDown(from: row, col: col)
            target = (targetRow * columns) + col
        }

        selectedIndex = target
        focusedTarget = .tile(shapes[target].id)
    }
}
