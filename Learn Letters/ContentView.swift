//
//  ContentView.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    private enum VoiceSettings {
        static let selectedVoiceIdentifierKey = "selectedVoiceIdentifier"
        static let voicesEnabledKey = "voicesEnabled"
    }

    @AppStorage(VoiceSettings.selectedVoiceIdentifierKey) private var selectedVoiceIdentifier = ""
    @AppStorage(VoiceSettings.voicesEnabledKey) private var voicesEnabled = true
    @StateObject private var speaker: LetterSpeaker
    @State private var selectedMode: AppMode?
    @State private var showModeSelection = true
    @State private var showingVoiceSelection = false

    init() {
        let storedVoiceIdentifier = UserDefaults.standard.string(forKey: VoiceSettings.selectedVoiceIdentifierKey)
        let storedVoicesEnabled = UserDefaults.standard.object(forKey: VoiceSettings.voicesEnabledKey) as? Bool ?? true
        let speaker = LetterSpeaker(preferredVoiceIdentifier: storedVoiceIdentifier?.isEmpty == false ? storedVoiceIdentifier : nil)
        speaker.isSpeechEnabled = storedVoicesEnabled
        _speaker = StateObject(wrappedValue: speaker)
    }

    var body: some View {
        rootView
            .onAppear {
                applyPreferredVoice()
            }
            .onChange(of: voicesEnabled) { _, newValue in
                speaker.isSpeechEnabled = newValue
            }
            #if os(tvOS)
            .focusEffectDisabled(true)
            #endif
    }

    @ViewBuilder
    private var rootView: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            IPadLearningView(
                speaker: speaker,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                voicesEnabled: $voicesEnabled
            )
        } else {
            IPhoneLearningView(
                speaker: speaker,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                voicesEnabled: $voicesEnabled
            )
        }
        #else
        legacyRootView
        #endif
    }

    @ViewBuilder
    private var legacyRootView: some View {
        if showingVoiceSelection {
            VoiceSelectionView(
                speaker: speaker,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                voicesEnabled: $voicesEnabled,
                onDone: {
                    showingVoiceSelection = false
                }
            )
        } else if showModeSelection {
            ModeSelectionView(
                selectedMode: $selectedMode,
                voicesEnabled: $voicesEnabled,
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
                } else if selectedMode == .random {
                    RandomPromptView(
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
        let preferredVoiceIdentifier = selectedVoiceIdentifier.isEmpty ? nil : selectedVoiceIdentifier

        if speaker.selectedVoiceIdentifier != preferredVoiceIdentifier {
            speaker.selectVoice(identifier: preferredVoiceIdentifier)
        }
        speaker.isSpeechEnabled = voicesEnabled
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
    @State private var detailAutoPlayStartedAt: Date?

    private let alphabet = LetterCard.samples
    private let gridDwellTime: TimeInterval = 1.0
    private let detailDwellTime: TimeInterval = 4.0

    private var currentLetter: LetterCard {
        alphabet[selectedIndex]
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

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
                    autoPlayStartedAt: detailAutoPlayStartedAt,
                    autoPlayInterval: detailDwellTime,
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
        detailAutoPlayStartedAt = Date()
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
        detailAutoPlayStartedAt = nil
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
    @State private var detailAutoPlayStartedAt: Date?

    private let numbers = NumberCard.samples
    private let gridDwellTime: TimeInterval = 1.0
    private let detailDwellTime: TimeInterval = 4.0

    private var currentNumber: NumberCard {
        numbers[selectedIndex]
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

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
                    autoPlayStartedAt: detailAutoPlayStartedAt,
                    autoPlayInterval: detailDwellTime,
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
        detailAutoPlayStartedAt = Date()
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
        detailAutoPlayStartedAt = nil
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

#if os(iOS)

private enum IPadSidebarSelection: Hashable {
    case mode(AppMode)
    case letter(String)
    case number(Int)
    case shape(ShapeKind)
    case colour(ColourKind)
    case random
    case voices
}

private struct IPadLearningView: View {
    @ObservedObject var speaker: LetterSpeaker
    @Binding var selectedVoiceIdentifier: String
    @Binding var voicesEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var selectedMode: AppMode?
    @State private var selection: IPadSidebarSelection? = .mode(.letters)
    
    @State private var currentLetterIndex: Int = 0
    @State private var currentNumberIndex: Int = 0
    @State private var currentShapeIndex: Int = 0
    @State private var currentColourIndex: Int = 0

    @State private var isAutoPlaying = false
    @State private var isAutoAdvancing = false
    @State private var autoPlayTimer: Timer?
    @State private var autoPlayStartedAt: Date?
    private let autoPlayDwellTime: TimeInterval = 4.0

    private let sidebarModeFontSize: CGFloat = 22
    private let sidebarItemFontSize: CGFloat = 20
    private let sidebarSecondaryFontSize: CGFloat = 16
    private let sidebarRowVerticalPadding: CGFloat = 8
    private let sidebarMinRowHeight: CGFloat = 64

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section("Learn") {
                    ForEach(AppMode.allCases) { mode in
                        NavigationLink(value: sidebarSelection(for: mode)) {
                            HStack(spacing: 12) {
                                Image(systemName: mode.systemImage)
                                Text(mode.title)
                            }
                            .font(.system(size: sidebarModeFontSize, weight: .semibold, design: .default))
                            .padding(.vertical, sidebarRowVerticalPadding)
                        }
                        .listRowBackground(selectedRowBackground(isSelected: selection == sidebarSelection(for: mode)))
                    }
                }

                if let selectedMode, selectedMode != .random {
                    Section(selectedMode.title) {
                        switch selectedMode {
                        case .letters:
                            ForEach(LetterCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.letter(card.letter)) {
                                    Text("\(card.uppercaseLetter)  ·  \(card.word)")
                                        .font(.system(size: sidebarItemFontSize, weight: .semibold, design: .default))
                                        .padding(.vertical, sidebarRowVerticalPadding)
                                }
                                .listRowBackground(selectedRowBackground(isSelected: selection == .letter(card.letter)))
                            }
                        case .numbers:
                            ForEach(NumberCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.number(card.number)) {
                                    Text("\(card.displayNumber)  ·  \(card.word)")
                                        .font(.system(size: sidebarItemFontSize, weight: .semibold, design: .default))
                                        .padding(.vertical, sidebarRowVerticalPadding)
                                }
                                .listRowBackground(selectedRowBackground(isSelected: selection == .number(card.number)))
                            }
                        case .shapes:
                            ForEach(ShapeCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.shape(card.kind)) {
                                    HStack(spacing: 12) {
                                        shapeSidebarIcon(for: card)
                                        Text(card.label)
                                    }
                                    .font(.system(size: sidebarItemFontSize, weight: .semibold, design: .default))
                                    .padding(.vertical, sidebarRowVerticalPadding)
                                }
                                .listRowBackground(selectedRowBackground(isSelected: selection == .shape(card.kind)))
                            }
                        case .colours:
                            ForEach(ColourCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.colour(card.kind)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "square.fill")
                                            .font(.system(size: 24, weight: .bold, design: .default))
                                            .foregroundStyle(card.color)
                                        Text(card.label)
                                    }
                                    .font(.system(size: sidebarItemFontSize, weight: .semibold, design: .default))
                                    .padding(.vertical, sidebarRowVerticalPadding)
                                }
                                .listRowBackground(selectedRowBackground(isSelected: selection == .colour(card.kind)))
                            }
                        case .random:
                            EmptyView()
                        }
                    }
                }

                Section("Settings") {
                    NavigationLink(value: IPadSidebarSelection.voices) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: voicesEnabled ? "speaker.wave.2" : "speaker.slash")
                                Text("Voices")
                            }
                            .font(.system(size: sidebarModeFontSize, weight: .semibold, design: .default))
                            
                            if voicesEnabled && !selectedVoiceIdentifier.isEmpty {
                                Text(speaker.selectedVoiceDisplayName)
                                    .font(.system(size: sidebarSecondaryFontSize, weight: .regular, design: .default))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 36)
                            }
                        }
                        .padding(.vertical, sidebarRowVerticalPadding)
                    }
                    .listRowBackground(selectedRowBackground(isSelected: selection == .voices))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .tint(.accentColor)
            .environment(\.defaultMinListRowHeight, sidebarMinRowHeight)
            .navigationTitle("Learn Things")
        } detail: {
            NavigationStack {
                ZStack {
                    Color(uiColor: .systemBackground).ignoresSafeArea()
                    detailContent
                }
                .navigationTitle(detailTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if isDetailCardSelected {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 8) {
                                if isAutoPlaying, let autoPlayStartedAt {
                                    AutoPlayProgressIndicator(
                                        startDate: autoPlayStartedAt,
                                        duration: autoPlayDwellTime,
                                        size: 28
                                    )
                                    .padding(.leading, 8)
                                }
                                Button(action: toggleAutoPlay) {
                                    Image(systemName: isAutoPlaying ? "pause.fill" : "play.fill")
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel(isAutoPlaying ? "Pause" : "Play")
                                .fixedSize()
                            }
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            selectedMode = .letters
            if selection == nil {
                selection = .mode(.letters)
            }
        }
        .onDisappear(perform: stopAutoPlay)
        .onChange(of: selection) { _, newValue in
            if isAutoAdvancing {
                isAutoAdvancing = false
            } else {
                stopAutoPlay()
            }
            handleSelectionChange(newValue)
        }
    }

    private var isDetailCardSelected: Bool {
        switch selection {
        case .letter, .number, .shape, .colour:
            return true
        default:
            return false
        }
    }

    private func toggleAutoPlay() {
        if isAutoPlaying {
            stopAutoPlay()
        } else {
            isAutoPlaying = true
            scheduleNextAutoPlayCard()
        }
    }

    private func scheduleNextAutoPlayCard() {
        autoPlayStartedAt = Date()
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: autoPlayDwellTime, repeats: false) { _ in
            if isAutoPlaying {
                advanceToNextCard()
                scheduleNextAutoPlayCard()
            }
        }
    }

    private func stopAutoPlay() {
        isAutoPlaying = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
        autoPlayStartedAt = nil
    }

    private func advanceToNextCard() {
        let next: IPadSidebarSelection
        switch selection {
        case .letter:
            currentLetterIndex = (currentLetterIndex + 1) % LetterCard.samples.count
            next = .letter(LetterCard.samples[currentLetterIndex].id)
        case .number:
            currentNumberIndex = (currentNumberIndex + 1) % NumberCard.samples.count
            next = .number(NumberCard.samples[currentNumberIndex].number)
        case .shape:
            currentShapeIndex = (currentShapeIndex + 1) % ShapeCard.samples.count
            next = .shape(ShapeCard.samples[currentShapeIndex].kind)
        case .colour:
            currentColourIndex = (currentColourIndex + 1) % ColourCard.samples.count
            next = .colour(ColourCard.samples[currentColourIndex].kind)
        default:
            stopAutoPlay()
            return
        }
        isAutoAdvancing = true
        selection = next
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .voices:
            VoiceSelectionView(
                speaker: speaker,
                selectedVoiceIdentifier: $selectedVoiceIdentifier,
                voicesEnabled: $voicesEnabled,
                onDone: {}
            )
        case .random:
            RandomPromptView(onBackToModeSelection: {
                selection = .mode(.random)
            })
        case .letter(let id):
            if let card = LetterCard.samples.first(where: { $0.id == id }) {
                IPadLetterDetailView(
                    card: card,
                    onSwipeLeft: {
                        currentLetterIndex = (currentLetterIndex + 1) % LetterCard.samples.count
                        selection = .letter(LetterCard.samples[currentLetterIndex].id)
                    },
                    onSwipeRight: {
                        currentLetterIndex = (currentLetterIndex - 1 + LetterCard.samples.count) % LetterCard.samples.count
                        selection = .letter(LetterCard.samples[currentLetterIndex].id)
                    }
                )
            }
        case .number(let number):
            if let card = NumberCard.samples.first(where: { $0.number == number }) {
                IPadNumberDetailView(
                    card: card,
                    onSwipeLeft: {
                        currentNumberIndex = (currentNumberIndex + 1) % NumberCard.samples.count
                        selection = .number(NumberCard.samples[currentNumberIndex].number)
                    },
                    onSwipeRight: {
                        currentNumberIndex = (currentNumberIndex - 1 + NumberCard.samples.count) % NumberCard.samples.count
                        selection = .number(NumberCard.samples[currentNumberIndex].number)
                    }
                )
            }
        case .shape(let kind):
            if let card = ShapeCard.samples.first(where: { $0.kind == kind }) {
                IPadShapeDetailView(
                    card: card,
                    onSwipeLeft: {
                        currentShapeIndex = (currentShapeIndex + 1) % ShapeCard.samples.count
                        selection = .shape(ShapeCard.samples[currentShapeIndex].kind)
                    },
                    onSwipeRight: {
                        currentShapeIndex = (currentShapeIndex - 1 + ShapeCard.samples.count) % ShapeCard.samples.count
                        selection = .shape(ShapeCard.samples[currentShapeIndex].kind)
                    }
                )
            }
        case .colour(let kind):
            if let card = ColourCard.samples.first(where: { $0.kind == kind }) {
                IPadColourDetailView(
                    card: card,
                    onSwipeLeft: {
                        currentColourIndex = (currentColourIndex + 1) % ColourCard.samples.count
                        selection = .colour(ColourCard.samples[currentColourIndex].kind)
                    },
                    onSwipeRight: {
                        currentColourIndex = (currentColourIndex - 1 + ColourCard.samples.count) % ColourCard.samples.count
                        selection = .colour(ColourCard.samples[currentColourIndex].kind)
                    }
                )
            }
        case .mode(.letters):
            LetterPosterGrid { selectedId in
                if let index = LetterCard.samples.firstIndex(where: { $0.id == selectedId }) {
                    currentLetterIndex = index
                }
                selection = .letter(selectedId)
            }
        case .mode(.numbers):
            NumberPosterGrid { selectedNumber in
                if let index = NumberCard.samples.firstIndex(where: { $0.number == selectedNumber }) {
                    currentNumberIndex = index
                }
                selection = .number(selectedNumber)
            }
        case .mode(.shapes):
            ShapePosterGrid { selectedKind in
                if let index = ShapeCard.samples.firstIndex(where: { $0.kind == selectedKind }) {
                    currentShapeIndex = index
                }
                selection = .shape(selectedKind)
            }
        case .mode(.colours):
            ColourPosterGrid { selectedKind in
                if let index = ColourCard.samples.firstIndex(where: { $0.kind == selectedKind }) {
                    currentColourIndex = index
                }
                selection = .colour(selectedKind)
            }
        case .mode(.random):
            EmptyView()
        case nil:
            EmptyView()
        }
    }

    private var detailTitle: String {
        switch selection {
        case .voices:
            return "Voices"
        case .random:
            return "Random"
        case .letter:
            return "Letters"
        case .number:
            return "Numbers"
        case .shape:
            return "Shapes"
        case .colour:
            return "Colours"
        case .mode(let mode):
            return mode.title
        case nil:
            return "Learn Things"
        }
    }

    private var placeholderLabel: String {
        guard let selectedMode else {
            return "Choose an item"
        }

        switch selectedMode {
        case .letters:
            return "Choose a letter"
        case .numbers:
            return "Choose a number"
        case .shapes:
            return "Choose a shape"
        case .colours:
            return "Choose a colour"
        case .random:
            return "Choose Random"
        }
    }

    private func sidebarSelection(for mode: AppMode) -> IPadSidebarSelection {
        switch mode {
        case .letters: return .mode(.letters)
        case .numbers: return .mode(.numbers)
        case .shapes: return .mode(.shapes)
        case .colours: return .mode(.colours)
        case .random: return .random
        }
    }

    private func handleSelectionChange(_ newValue: IPadSidebarSelection?) {
        switch newValue {
        case .mode(let mode):
            selectedMode = mode
        case .letter(let id):
            selectedMode = .letters
            if let index = LetterCard.samples.firstIndex(where: { $0.id == id }) {
                currentLetterIndex = index
            }
            if let card = LetterCard.samples.first(where: { $0.id == id }) {
                speaker.speak(phraseFor: card)
            }
        case .number(let number):
            selectedMode = .numbers
            if let index = NumberCard.samples.firstIndex(where: { $0.number == number }) {
                currentNumberIndex = index
            }
            if let card = NumberCard.samples.first(where: { $0.number == number }) {
                speaker.speak(phraseFor: card)
            }
        case .shape(let kind):
            selectedMode = .shapes
            if let index = ShapeCard.samples.firstIndex(where: { $0.kind == kind }) {
                currentShapeIndex = index
            }
            if let card = ShapeCard.samples.first(where: { $0.kind == kind }) {
                speaker.speak(phraseFor: card)
            }
        case .colour(let kind):
            selectedMode = .colours
            if let index = ColourCard.samples.firstIndex(where: { $0.kind == kind }) {
                currentColourIndex = index
            }
            if let card = ColourCard.samples.first(where: { $0.kind == kind }) {
                speaker.speak(colourFor: card)
            }
        case .random:
            selectedMode = .random
        case .voices:
            break
        case nil:
            break
        }
    }

    @ViewBuilder
    private func shapeSidebarIcon(for card: ShapeCard) -> some View {
        let size = shapeSidebarIconSize(for: card.kind)

        ShapeSymbolView(kind: card.kind, color: card.color)
            .frame(width: size.width, height: size.height)
            .frame(width: 30, height: 24)
    }

    private func shapeSidebarIconSize(for kind: ShapeKind) -> CGSize {
        switch kind {
        case .oval, .rectangle, .arrow, .cloud, .rhombus:
            return CGSize(width: 24, height: 18)
        case .diamond:
            return CGSize(width: 22, height: 22)
        case .crescent:
            return CGSize(width: 20, height: 20)
        default:
            return CGSize(width: 22, height: 22)
        }
    }

    @ViewBuilder
    private func selectedRowBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.38 : 0.18))
        } else {
            Color.clear
        }
    }
}

private struct IPadPosterPage<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: (CGSize) -> Content
    @Environment(\.colorScheme) private var colorScheme
    @State private var headerHeight: CGFloat = 0

    init(title: String, subtitle: String? = nil, @ViewBuilder content: @escaping (CGSize) -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let verticalSpacing = min(geometry.size.height * 0.032, 28)
            let horizontalPadding = min(geometry.size.width * 0.045, 36)
            let bottomPadding = min(geometry.size.height * 0.045, 36)
            let contentSize = CGSize(
                width: max(0, geometry.size.width - (horizontalPadding * 2)),
                height: max(0, geometry.size.height - headerHeight - verticalSpacing - bottomPadding)
            )

            ScrollView {
                VStack(spacing: verticalSpacing) {
                    VStack(spacing: min(geometry.size.height * 0.01, 10)) {
                        Text(title)
                            .font(.system(size: min(geometry.size.width * 0.06, 44), weight: .bold, design: .default))
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)

                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: min(geometry.size.width * 0.028, 20), weight: .semibold, design: .default))
                                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.78) : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, min(geometry.size.height * 0.035, 30))
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { newHeight in
                        headerHeight = newHeight
                    }

                    content(contentSize)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private struct LetterPosterGrid: View {
    let onSelectLetter: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        IPadPosterPage(title: "Letters", subtitle: "Tap a letter") { availableSize in
            let columns = max(4, min(7, Int(availableSize.width / 112)))
            let spacing = min(availableSize.width * 0.018, 16)
            let itemWidth = (availableSize.width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
            let tileHeight = posterTileHeight(count: LetterCard.samples.count, columns: columns, spacing: spacing, availableHeight: availableSize.height, preferred: min(max(itemWidth * 1.18, 108), 156), minimum: 80)
            let letterSize = tileHeight * 0.40
            let wordSize = tileHeight * 0.14

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: columns), spacing: spacing) {
                ForEach(LetterCard.samples) { card in
                    let symbolColor = posterLetterColor(for: card)

                    Button {
                        onSelectLetter(card.id)
                    } label: {
                        VStack(spacing: tileHeight * 0.07) {
                            LetterPairLabel(
                                uppercase: card.uppercaseLetter,
                                lowercase: card.lowercaseLetter,
                                separator: " ",
                                uppercaseColor: symbolColor,
                                lowercaseColor: symbolColor.opacity(0.72),
                                font: .system(size: letterSize, weight: .bold, design: .rounded),
                                minimumScaleFactor: 0.55,
                                horizontalInset: max(4, letterSize * 0.08)
                            )

                            Text(card.word)
                                .font(.system(size: wordSize, weight: .semibold, design: .default))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(width: itemWidth, height: tileHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(colorScheme == .dark ? .white.opacity(0.12) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func posterLetterColor(for card: LetterCard) -> Color {
        if colorScheme == .dark && card.uppercaseLetter == "Z" {
            return .white
        }

        return card.color
    }
}

private struct NumberPosterGrid: View {
    let onSelectNumber: (Int) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        IPadPosterPage(title: "Numbers", subtitle: "Tap a number") { availableSize in
            let columns = max(3, min(4, Int(availableSize.width / 172)))
            let spacing = min(availableSize.width * 0.022, 18)
            let itemWidth = (availableSize.width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
            let tileHeight = posterTileHeight(count: NumberCard.samples.count, columns: columns, spacing: spacing, availableHeight: availableSize.height, preferred: min(max(itemWidth * 1.16, 140), 210), minimum: 110)
            let numberSize = tileHeight * 0.34
            let wordSize = tileHeight * 0.11
            let dotsAreaHeight = tileHeight * 0.24

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: columns), spacing: spacing) {
                ForEach(NumberCard.samples) { card in
                    Button {
                        onSelectNumber(card.number)
                    } label: {
                        VStack(spacing: tileHeight * 0.05) {
                            Text(card.displayNumber)
                                .font(.system(size: numberSize, weight: .bold, design: .rounded))
                                .foregroundStyle(card.color)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)

                            Text(card.word)
                                .font(.system(size: wordSize, weight: .semibold, design: .default))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            PosterNumberDots(number: card.number)
                                .frame(height: dotsAreaHeight, alignment: .top)
                        }
                        .frame(width: itemWidth, height: tileHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(colorScheme == .dark ? .white.opacity(0.12) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ShapePosterGrid: View {
    let onSelectShape: (ShapeKind) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        IPadPosterPage(title: "Shapes", subtitle: "Tap a shape") { availableSize in
            let columns = max(3, min(4, Int(availableSize.width / 170)))
            let spacing = min(availableSize.width * 0.022, 18)
            let itemWidth = (availableSize.width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
            let tileHeight = posterTileHeight(count: ShapeCard.samples.count, columns: columns, spacing: spacing, availableHeight: availableSize.height, preferred: min(max(itemWidth * 1.08, 148), 212), minimum: 104)
            let labelSize = tileHeight * 0.10
            let shapeBase = min(itemWidth * 0.64, tileHeight * 0.7)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: columns), spacing: spacing) {
                ForEach(ShapeCard.samples) { card in
                    Button {
                        onSelectShape(card.kind)
                    } label: {
                        VStack(spacing: tileHeight * 0.10) {
                            ShapeSymbolView(kind: card.kind, color: card.color)
                                .frame(width: shapeSize(for: card.kind, baseWidth: shapeBase).width, height: shapeSize(for: card.kind, baseWidth: shapeBase).height)
                                .frame(maxHeight: .infinity)

                            Text(card.label)
                                .font(.system(size: labelSize, weight: .semibold, design: .default))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.top, tileHeight * 0.12)
                        .padding(.bottom, tileHeight * 0.12)
                        .frame(width: itemWidth, height: tileHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(colorScheme == .dark ? .white.opacity(0.12) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func shapeSize(for kind: ShapeKind, baseWidth: CGFloat) -> CGSize {
        switch kind {
        case .oval:
            return CGSize(width: baseWidth, height: baseWidth * 0.56)
        case .rectangle:
            return CGSize(width: baseWidth, height: baseWidth * 0.58)
        case .arrow:
            return CGSize(width: baseWidth, height: baseWidth * 0.58)
        case .cloud:
            return CGSize(width: baseWidth * 0.92, height: baseWidth * 0.68)
        case .rhombus:
            return CGSize(width: baseWidth * 0.92, height: baseWidth * 0.64)
        default:
            return CGSize(width: baseWidth * 0.78, height: baseWidth * 0.78)
        }
    }
}

private struct ColourPosterGrid: View {
    let onSelectColour: (ColourKind) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        IPadPosterPage(title: "Colours", subtitle: "Tap a colour") { availableSize in
            let columns = max(3, min(4, Int(availableSize.width / 172)))
            let spacing = min(availableSize.width * 0.022, 18)
            let itemWidth = (availableSize.width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
            let tileHeight = posterTileHeight(count: ColourCard.samples.count, columns: columns, spacing: spacing, availableHeight: availableSize.height, preferred: min(max(itemWidth * 0.92, 126), 176), minimum: 90)
            let labelSize = tileHeight * 0.115

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: columns), spacing: spacing) {
                ForEach(ColourCard.samples) { card in
                    Button {
                        onSelectColour(card.kind)
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(card.color)
                                .overlay {
                                    if card.kind == .white {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color(white: 0.76), lineWidth: 2)
                                    }
                                }

                            Text(card.label)
                                .font(.system(size: labelSize, weight: .bold, design: .default))
                                .foregroundStyle(card.kind.labelColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, tileHeight * 0.12)
                                .padding(.vertical, tileHeight * 0.10)
                        }
                        .frame(width: itemWidth, height: tileHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(colorScheme == .dark ? .white.opacity(0.12) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Fits all rows in the available height when possible, never shrinking below `minimum`.
private func posterTileHeight(count: Int, columns: Int, spacing: CGFloat, availableHeight: CGFloat, preferred: CGFloat, minimum: CGFloat) -> CGFloat {
    let rows = max(1, (count + columns - 1) / columns)
    let fitting = (availableHeight - (CGFloat(rows - 1) * spacing)) / CGFloat(rows)
    return floor(max(minimum, min(preferred, fitting)))
}

private struct PosterNumberDots: View {
    let number: Int

    var body: some View {
        let dotsPerRow = number <= 5 ? max(number, 1) : 5
        let rows = number == 0 ? 1 : (number + dotsPerRow - 1) / dotsPerRow
        let dotSize: CGFloat = number >= 10 ? 10 : 12

        VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    Spacer(minLength: 0)
                    ForEach(0..<dotsPerRow, id: \.self) { col in
                        if number > 0, row * dotsPerRow + col < number {
                            Circle()
                                .fill(Color(white: 0.5))
                                .frame(width: dotSize, height: dotSize)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .opacity(number == 0 ? 0 : 1)
    }
}

private struct IPadPlaceholderView: View {
    let title: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "rectangle.and.hand.point.up.left")
                .font(.system(size: 75))
                .imageScale(.large)
        }
    }
}

private struct IPadLetterDetailView: View {
    let card: LetterCard
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let symbolSize = min(geometry.size.width * 0.40, geometry.size.height * 0.42)

            VStack(spacing: 28) {
                Text(card.uppercaseLetter)
                    .font(.system(size: symbolSize, weight: .bold, design: .rounded))
                    .foregroundStyle(card.color)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(card.word)
                    .font(.system(size: min(geometry.size.height * 0.08, 56), weight: .bold, design: .default))
                    .foregroundStyle(.primary)

                Text("\(card.uppercaseLetter)  ·  \(card.lowercaseLetter)")
                    .font(.system(size: min(geometry.size.height * 0.045, 32), weight: .semibold, design: .default))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
        .detailNavigationGestures(onBack: onSwipeRight, onForward: onSwipeLeft)
    }
}

private struct IPadNumberDetailView: View {
    let card: NumberCard
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    private let dotsAreaHeight: CGFloat = 180

    var body: some View {
        GeometryReader { geometry in
            let symbolSize = min(geometry.size.width * 0.40, geometry.size.height * 0.42)

            VStack(spacing: 28) {
                Text(card.displayNumber)
                    .font(.system(size: symbolSize, weight: .bold, design: .rounded))
                    .foregroundStyle(card.color)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(card.word)
                    .font(.system(size: min(geometry.size.height * 0.08, 56), weight: .bold, design: .default))
                    .foregroundStyle(.primary)

                dotsForNumber(card.number)
                    .frame(height: dotsAreaHeight, alignment: .top)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
        .detailNavigationGestures(onBack: onSwipeRight, onForward: onSwipeLeft)
    }

    private func dotsForNumber(_ number: Int) -> some View {
        if number == 0 {
            return AnyView(
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 30, height: 30)
                    }
                }
                .opacity(0)
            )
        }

        let dotsPerRow: Int
        if number <= 5 {
            dotsPerRow = number
        } else {
            dotsPerRow = 5
        }

        let rows = (number + dotsPerRow - 1) / dotsPerRow
        let dotSize: CGFloat = 30

        return AnyView(
            VStack(spacing: 12) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 12) {
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
        )
    }
}

private struct IPadShapeDetailView: View {
    let card: ShapeCard
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let maxSize = min(geometry.size.width * 0.44, geometry.size.height * 0.48)
            let symbolSize = shapeSymbolSize(maxSize: maxSize)

            VStack(spacing: 28) {
                ShapeSymbolView(kind: card.kind, color: card.color)
                    .frame(width: symbolSize.width, height: symbolSize.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(card.label)
                    .font(.system(size: min(geometry.size.height * 0.08, 56), weight: .bold, design: .default))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
        .detailNavigationGestures(onBack: onSwipeRight, onForward: onSwipeLeft)
    }

    private func shapeSymbolSize(maxSize: CGFloat) -> CGSize {
        switch card.kind {
        case .oval:
            return CGSize(width: maxSize, height: maxSize * 0.68)
        case .rectangle:
            return CGSize(width: maxSize, height: maxSize * 0.7)
        case .arrow:
            return CGSize(width: maxSize, height: maxSize * 0.62)
        case .cloud:
            return CGSize(width: maxSize, height: maxSize * 0.72)
        case .rhombus:
            return CGSize(width: maxSize, height: maxSize * 0.78)
        default:
            return CGSize(width: maxSize, height: maxSize)
        }
    }
}

private struct IPadColourDetailView: View {
    let card: ColourCard
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    var body: some View {
        ZStack {
            card.color.ignoresSafeArea()

            GeometryReader { geometry in
                Text(card.label)
                    .font(.system(size: min(geometry.size.height * 0.21, geometry.size.width * 0.18), weight: .bold, design: .default))
                    .foregroundStyle(card.kind.labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, geometry.size.width * 0.08)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .detailNavigationGestures(onBack: onSwipeRight, onForward: onSwipeLeft)
    }
}

// One gesture handles both taps and swipes so neither can swallow the other.
// Movement under the threshold is a tap: left third goes back, the rest goes forward.
private struct DetailNavigationGestures: ViewModifier {
    let onBack: () -> Void
    let onForward: () -> Void

    private let swipeThreshold: CGFloat = 40

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleGesture(value, width: geometry.size.width)
                        }
                )
        }
    }

    private func handleGesture(_ value: DragGesture.Value, width: CGFloat) {
        let horizontal = value.translation.width
        let vertical = value.translation.height

        if abs(horizontal) < swipeThreshold && abs(vertical) < swipeThreshold {
            if value.startLocation.x < width / 3 {
                onBack()
            } else {
                onForward()
            }
            return
        }

        guard abs(horizontal) > abs(vertical) else { return }

        if horizontal < 0 {
            onForward()
        } else {
            onBack()
        }
    }
}

private extension View {
    func detailNavigationGestures(onBack: @escaping () -> Void, onForward: @escaping () -> Void) -> some View {
        modifier(DetailNavigationGestures(onBack: onBack, onForward: onForward))
    }
}

#endif

#Preview {
    ContentView()
}
