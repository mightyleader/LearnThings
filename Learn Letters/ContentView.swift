//
//  ContentView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var speaker = LetterSpeaker()
    @State private var selectedVoiceIdentifier = ""
    @State private var selectedMode: AppMode?
    @State private var showModeSelection = true
    @State private var showingVoiceSelection = false

    var body: some View {
        rootView
            .onAppear {
                applyPreferredVoice()
            }
            .focusEffectDisabled(true)
    }

    @ViewBuilder
    private var rootView: some View {
        if showingVoiceSelection {
            VoiceSelectionView(
                speaker: speaker,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                onDone: {
                    showingVoiceSelection = false
                }
            )
        } else if showModeSelection {
            ModeSelectionView(
                selectedMode: $selectedMode,
                onOpenVoiceSettings: {
                    selectedVoiceIdentifier = speaker.selectedVoiceIdentifier ?? speaker.recommendedVoiceIdentifier ?? ""
                    showingVoiceSelection = true
                }
            )
            .onChange(of: selectedMode) { _, _ in
                withAnimation {
                    showModeSelection = false
                }
            }
        } else {
            Group {
                if selectedMode == .letters {
                    LetterContentView(
                        speaker: speaker,
                        onBackToModeSelection: {
                            selectedMode = nil
                            showModeSelection = true
                        }
                    )
                } else if selectedMode == .numbers {
                    NumberContentView(
                        speaker: speaker,
                        onBackToModeSelection: {
                            selectedMode = nil
                            showModeSelection = true
                        }
                    )
                } else if selectedMode == .shapes {
                    ShapeContentView(
                        speaker: speaker,
                        onBackToModeSelection: {
                            selectedMode = nil
                            showModeSelection = true
                        }
                    )
                } else if selectedMode == .colours {
                    ColourContentView(
                        speaker: speaker,
                        onBackToModeSelection: {
                            selectedMode = nil
                            showModeSelection = true
                        }
                    )
                }
            }
        }
    }

    private func applyPreferredVoice() {
        if speaker.selectedVoiceIdentifier != speaker.recommendedVoiceIdentifier {
            speaker.selectVoice(identifier: speaker.recommendedVoiceIdentifier)
        }
        selectedVoiceIdentifier = speaker.selectedVoiceIdentifier ?? speaker.recommendedVoiceIdentifier ?? ""
    }
}

// MARK: - Letter Content

struct LetterContentView: View {
    @ObservedObject var speaker: LetterSpeaker
    var onBackToModeSelection: () -> Void

    @State private var selectedIndex = 0
    @State private var showingGrid = true
    @FocusState private var focusedTarget: FocusTarget?
    @State private var isAutoPlayActive = false
    @State private var autoPlayTimer: Timer?

    private let alphabet = LetterCard.samples
    private let gridDwellTime: TimeInterval = 1.0
    private let detailDwellTime: TimeInterval = 4.0

    private var currentLetter: LetterCard {
        alphabet[selectedIndex]
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showingGrid {
                GridView(
                    alphabet: alphabet,
                    focusedTarget: _focusedTarget,
                    onBackToModeSelection: onBackToModeSelection,
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
        .navigationTitle("Letters")
        .onAppear {
            focusedTarget = .tile(alphabet[selectedIndex].letter)
            speaker.speak(letterFor: alphabet[selectedIndex])
        }
        .onDisappear {
            stopAutoPlay()
        }
        .onChange(of: selectedIndex) { _, newValue in
            if showingGrid {
                speaker.speak(letterFor: alphabet[newValue])
            } else {
                speaker.speak(phraseFor: alphabet[newValue])
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
            previousLetter()
        case .right:
            nextLetter()
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

    private func handleGridMove(_ direction: NavigationDirection) {
        stopAutoPlay()
        guard !alphabet.isEmpty else { return }

        let columns = AppLayout.gridColumns
        let count = alphabet.count
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
        focusedTarget = .tile(alphabet[target].letter)
    }
}

// MARK: - Number Content

struct NumberContentView: View {
    @ObservedObject var speaker: LetterSpeaker
    var onBackToModeSelection: () -> Void

    @State private var selectedIndex = 0
    @State private var showingGrid = true
    @FocusState private var focusedTarget: FocusTarget?
    @State private var isAutoPlayActive = false
    @State private var autoPlayTimer: Timer?

    private let numbers = NumberCard.samples
    private let gridDwellTime: TimeInterval = 1.0
    private let detailDwellTime: TimeInterval = 4.0

    private var currentNumber: NumberCard {
        numbers[selectedIndex]
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showingGrid {
                NumberGridView(
                    numbers: numbers,
                    focusedTarget: _focusedTarget,
                    onBackToModeSelection: onBackToModeSelection,
                    onGridMove: handleGridMove,
                    onGridPlayPause: handleGridPlayPause,
                    onSelectTile: handleSelectTile
                )
            } else {
                NumberDetailView(
                    currentNumber: currentNumber,
                    focusedTarget: _focusedTarget,
                    onDetailMove: handleHeroMove,
                    onDetailPlayPause: handleDetailPlayPause,
                    onExit: handleExitToGrid,
                    onSpeak: { speaker.speak(phraseFor: currentNumber) }
                )
            }
        }
        .navigationTitle("Numbers")
        .onAppear {
            focusedTarget = .tile(numbers[selectedIndex].id)
            speaker.speak(numberFor: numbers[selectedIndex])
        }
        .onDisappear {
            stopAutoPlay()
        }
        .onChange(of: selectedIndex) { _, newValue in
            if showingGrid {
                speaker.speak(numberFor: numbers[newValue])
            } else {
                speaker.speak(phraseFor: numbers[newValue])
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
            previousNumber()
        case .right:
            nextNumber()
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
            focusedTarget = .tile(currentNumber.id)
        }
    }

    private func previousNumber() {
        selectedIndex = (selectedIndex - 1 + numbers.count) % numbers.count
    }

    private func nextNumber() {
        selectedIndex = (selectedIndex + 1) % numbers.count
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
        scheduleNextGridNumber()
    }

    private func startAutoPlayDetail() {
        isAutoPlayActive = true
        scheduleNextDetailNumber()
    }

    private func scheduleNextGridNumber() {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: gridDwellTime, repeats: false) { _ in
            if isAutoPlayActive {
                nextNumber()
                focusedTarget = .tile(numbers[selectedIndex].id)
                scheduleNextGridNumber()
            }
        }
    }

    private func scheduleNextDetailNumber() {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: detailDwellTime, repeats: false) { _ in
            if isAutoPlayActive {
                nextNumber()
                scheduleNextDetailNumber()
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
        guard !numbers.isEmpty else { return }

        let columns = AppLayout.gridColumns
        let count = numbers.count
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
        focusedTarget = .tile(numbers[target].id)
    }
}

#Preview {
    ContentView()
}
