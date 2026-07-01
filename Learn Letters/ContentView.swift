//
//  ContentView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var speaker = LetterSpeaker()
    @State private var selectedIndex = 0
    @State private var showingGrid = true
    @FocusState private var focusedTarget: FocusTarget?
    @State private var isAutoPlayActive = false
    @State private var autoPlayTimer: Timer?

    private let alphabet = LetterCard.samples
    private let letterFontName = "AkzidenzGroteskBE-Md"
    private let tileFontName = "AkzidenzGroteskBE-Bold"
    private let wordFontName = "AkzidenzGroteskBE-Bold"
    private let gridDwellTime: TimeInterval = 1.0
    private let detailDwellTime: TimeInterval = 3.0

    private var currentLetter: LetterCard {
        alphabet[selectedIndex]
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showingGrid {
                GridView(
                    alphabet: alphabet,
                    selectedIndex: $selectedIndex,
                    showingGrid: $showingGrid,
                    focusedTarget: _focusedTarget,
                    isAutoPlayActive: $isAutoPlayActive,
                    onGridMove: handleGridMove,
                    onGridPlayPause: handleGridPlayPause,
                    onSelectTile: handleSelectTile
                )
            } else {
                DetailView(
                    currentLetter: currentLetter,
                    focusedTarget: _focusedTarget,
                    onDetailMove: handleHeroMove,
                    onDetailPlayPause: handleDetailPlayPause,
                    onExit: handleExitToGrid,
                    onSpeak: { speaker.speak(phraseFor: currentLetter) }
                )
            }
        }
        .onAppear {
            focusedTarget = .tile(alphabet[selectedIndex].letter)
            // selectedIndex starts at 0, so onChange does not fire on first launch.
            speaker.speak(letterFor: alphabet[selectedIndex])
        }
        .onDisappear {
            stopAutoPlay()
        }
        .onChange(of: selectedIndex) { _, newValue in
            if showingGrid {
                speaker.speak(letterFor: alphabet[newValue])
            }
            else {
                speaker.speak(phraseFor: alphabet[newValue])
            }
        }
        .onChange(of: showingGrid) { _, _ in
            // Stop autoplay when switching views
            stopAutoPlay()
        }
    }

    private func handleHeroMove(_ direction: MoveCommandDirection) {
        stopAutoPlay()
        switch direction {
        case .left:
            previousLetter()
        case .right:
            nextLetter()
        default:
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
        // Use DispatchQueue to allow the view hierarchy to update before setting focus
        DispatchQueue.main.async {
            focusedTarget = .tile(currentLetter.letter)
        }
    }

    private func previousLetter() {
        selectedIndex = (selectedIndex - 1 + alphabet.count) % alphabet.count
    }

    private func nextLetter() {
        selectedIndex = (selectedIndex + 1) % alphabet.count
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
        scheduleNextGridLetter()
    }

    private func startAutoPlayDetail() {
        isAutoPlayActive = true
        scheduleNextDetailLetter()
    }

    private func scheduleNextGridLetter() {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: gridDwellTime, repeats: false) { _ in
            if isAutoPlayActive {
                nextLetter()
                focusedTarget = .tile(alphabet[selectedIndex].letter)
                scheduleNextGridLetter()
            }
        }
    }

    private func scheduleNextDetailLetter() {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: detailDwellTime, repeats: false) { _ in
            if isAutoPlayActive {
                nextLetter()
                scheduleNextDetailLetter()
            }
        }
    }

    private func stopAutoPlay() {
        isAutoPlayActive = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }

    private func handleGridMove(_ direction: MoveCommandDirection) {
        stopAutoPlay()
        guard !alphabet.isEmpty else { return }

        let columns = Layout.gridColumns
        let count = alphabet.count
        let lastIndex = count - 1

        // Keep movement deterministic to avoid double-focus drift.
        let currentIndex = selectedIndex
        let row = currentIndex / columns
        let col = currentIndex % columns

        let totalRows = Int(ceil(Double(count) / Double(columns)))

        // ...existing code...

        func rowEndIndex(_ r: Int) -> Int {
            min(((r + 1) * columns) - 1, lastIndex)
        }

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
            // Mirror right movement: step backward, wrapping from A to Z.
            target = (currentIndex == 0) ? lastIndex : (currentIndex - 1)
        case .right:
            // Move linearly through the grid; wrap to A after the last tile.
            target = (currentIndex == lastIndex) ? 0 : (currentIndex + 1)
        case .up:
            let targetRow = nextValidRowUp(from: row, col: col)
            target = (targetRow * columns) + col
        case .down:
            let targetRow = nextValidRowDown(from: row, col: col)
            target = (targetRow * columns) + col
        default:
            return
        }

        selectedIndex = target
        focusedTarget = .tile(alphabet[target].letter)
    }
}

#Preview {
    ContentView()
}
