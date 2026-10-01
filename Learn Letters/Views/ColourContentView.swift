//
//  ColourContentView.swift
//  Learn Letters
//

import SwiftUI

struct ColourContentView: View {
    @ObservedObject var speaker: LetterSpeaker
    var onBackToModeSelection: () -> Void

    @State private var selectedIndex = 0
    @State private var showingGrid = true
    @FocusState private var focusedTarget: FocusTarget?
    @State private var isAutoPlayActive = false
    @State private var autoPlayTimer: Timer?

    private let colours = ColourCard.samples
    private let columns = 4
    private let gridDwellTime: TimeInterval = 1.0
    private let detailDwellTime: TimeInterval = 3.0

    private var currentColour: ColourCard { colours[selectedIndex] }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showingGrid {
                ColourGridView(
                    colours: colours,
                    focusedTarget: _focusedTarget,
                    onBackToModeSelection: onBackToModeSelection,
                    onGridMove: handleGridMove,
                    onGridPlayPause: handleGridPlayPause,
                    onSelectTile: handleSelectTile
                )
            } else {
                ColourDetailView(
                    currentColour: currentColour,
                    focusedTarget: _focusedTarget,
                    onDetailMove: handleDetailMove,
                    onDetailPlayPause: handleDetailPlayPause,
                    onExit: handleExitToGrid,
                    onSpeak: { speaker.speak(colourFor: currentColour) }
                )
            }
        }
        .onAppear {
            focusedTarget = .tile(currentColour.id)
            speaker.speak(colourFor: currentColour)
        }
        .onDisappear(perform: stopAutoPlay)
        .onChange(of: selectedIndex) { _, newValue in
            speaker.speak(colourFor: colours[newValue])
        }
        .onChange(of: showingGrid) { _, _ in stopAutoPlay() }
    }

    private func handleSelectTile(_ index: Int) {
        stopAutoPlay()
        selectedIndex = index
        showingGrid = false
        focusedTarget = .hero
    }

    private func handleExitToGrid() {
        stopAutoPlay()
        showingGrid = true
        DispatchQueue.main.async {
            focusedTarget = .tile(currentColour.id)
        }
    }

    private func handleDetailMove(_ direction: NavigationDirection) {
        stopAutoPlay()
        switch direction {
        case .left: selectedIndex = (selectedIndex - 1 + colours.count) % colours.count
        case .right: selectedIndex = (selectedIndex + 1) % colours.count
        case .up, .down: break
        }
    }

    private func handleGridPlayPause() {
        if isAutoPlayActive {
            stopAutoPlay()
        } else {
            isAutoPlayActive = true
            scheduleNextColour(after: gridDwellTime)
        }
    }

    private func handleDetailPlayPause() {
        if isAutoPlayActive {
            stopAutoPlay()
        } else {
            isAutoPlayActive = true
            scheduleNextColour(after: detailDwellTime)
        }
    }

    private func scheduleNextColour(after delay: TimeInterval) {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            guard isAutoPlayActive else { return }
            selectedIndex = (selectedIndex + 1) % colours.count
            if showingGrid { focusedTarget = .tile(currentColour.id) }
            scheduleNextColour(after: delay)
        }
    }

    private func stopAutoPlay() {
        isAutoPlayActive = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }

    private func handleGridMove(_ direction: NavigationDirection) {
        stopAutoPlay()
        let count = colours.count
        let currentRow = selectedIndex / columns
        let column = selectedIndex % columns
        let rowCount = (count + columns - 1) / columns

        switch direction {
        case .left:
            selectedIndex = (selectedIndex - 1 + count) % count
        case .right:
            selectedIndex = (selectedIndex + 1) % count
        case .up, .down:
            let step = direction == .down ? 1 : -1
            for distance in 1...rowCount {
                let row = (currentRow + step * distance + rowCount * distance) % rowCount
                let candidate = row * columns + column
                if candidate < count {
                    selectedIndex = candidate
                    break
                }
            }
        }
        focusedTarget = .tile(currentColour.id)
    }
}