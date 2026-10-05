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
            legacyRootView
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

    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var selectedMode: AppMode?
    @State private var selection: IPadSidebarSelection? = .mode(.letters)
    
    @State private var currentLetterIndex: Int = 0
    @State private var currentNumberIndex: Int = 0
    @State private var currentShapeIndex: Int = 0
    @State private var currentColourIndex: Int = 0

    private let fontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section("Learn") {
                    ForEach(AppMode.allCases) { mode in
                        NavigationLink(value: sidebarSelection(for: mode)) {
                            Label(mode.title, systemImage: mode.systemImage)
                                .font(.custom(fontName, size: 17))
                        }
                    }
                }

                if let selectedMode, selectedMode != .random {
                    Section(selectedMode.title) {
                        switch selectedMode {
                        case .letters:
                            ForEach(LetterCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.letter(card.letter)) {
                                    Text("\(card.uppercaseLetter)  ·  \(card.word)")
                                        .font(.custom(fontName, size: 16))
                                }
                            }
                        case .numbers:
                            ForEach(NumberCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.number(card.number)) {
                                    Text("\(card.displayNumber)  ·  \(card.word)")
                                        .font(.custom(fontName, size: 16))
                                }
                            }
                        case .shapes:
                            ForEach(ShapeCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.shape(card.kind)) {
                                    Label {
                                        Text(card.label)
                                            .font(.custom(fontName, size: 16))
                                    } icon: {
                                        shapeSidebarIcon(for: card)
                                    }
                                }
                            }
                        case .colours:
                            ForEach(ColourCard.samples) { card in
                                NavigationLink(value: IPadSidebarSelection.colour(card.kind)) {
                                    Label {
                                        Text(card.label)
                                            .font(.custom(fontName, size: 16))
                                    } icon: {
                                        Image(systemName: "square.fill")
                                            .foregroundStyle(card.color)
                                    }
                                }
                            }
                        case .random:
                            EmptyView()
                        }
                    }
                }

                Section("Settings") {
                    NavigationLink(value: IPadSidebarSelection.voices) {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Voices", systemImage: voicesEnabled ? "speaker.wave.2" : "speaker.slash")
                                .font(.custom(fontName, size: 17))
                            
                            if voicesEnabled && !selectedVoiceIdentifier.isEmpty {
                                Text(speaker.selectedVoiceDisplayName)
                                    .font(.custom(fontName, size: 13))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 28)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Learn Things")
        } detail: {
            NavigationStack {
                ZStack {
                    Color(uiColor: .systemBackground).ignoresSafeArea()
                    detailContent
                }
                .navigationTitle(detailTitle)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            selectedMode = .letters
            if selection == nil {
                selection = .mode(.letters)
            }
        }
        .onChange(of: selection) { _, newValue in
            handleSelectionChange(newValue)
        }
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
        case .mode, nil:
            IPadPlaceholderView(
                title: placeholderLabel,
                fontName: fontName
            )
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
            .frame(width: 22, height: 18)
    }

    private func shapeSidebarIconSize(for kind: ShapeKind) -> CGSize {
        switch kind {
        case .oval, .rectangle, .arrow, .cloud, .rhombus:
            return CGSize(width: 18, height: 14)
        case .diamond:
            return CGSize(width: 16, height: 16)
        case .crescent:
            return CGSize(width: 15, height: 15)
        default:
            return CGSize(width: 16, height: 16)
        }
    }
}

private struct IPadPlaceholderView: View {
    let title: String
    let fontName: String

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

    private let fontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geometry in
            let symbolSize = min(geometry.size.width * 0.40, geometry.size.height * 0.42)

            VStack(spacing: 28) {
                Text(card.uppercaseLetter)
                    .font(.custom(fontName, size: symbolSize))
                    .foregroundStyle(card.color)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(card.word)
                    .font(.custom(fontName, size: min(geometry.size.height * 0.08, 56)))
                    .foregroundStyle(.primary)

                Text("\(card.uppercaseLetter)  ·  \(card.lowercaseLetter)")
                    .font(.custom(fontName, size: min(geometry.size.height * 0.045, 32)))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        onSwipeLeft()
                    } else if gesture.translation.width > 50 {
                        onSwipeRight()
                    }
                }
        )
    }
}

private struct IPadNumberDetailView: View {
    let card: NumberCard
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    private let fontName = "AkzidenzGroteskBE-Bold"
    private let dotsAreaHeight: CGFloat = 180

    var body: some View {
        GeometryReader { geometry in
            let symbolSize = min(geometry.size.width * 0.40, geometry.size.height * 0.42)

            VStack(spacing: 28) {
                Text(card.displayNumber)
                    .font(.custom(fontName, size: symbolSize))
                    .foregroundStyle(card.color)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(card.word)
                    .font(.custom(fontName, size: min(geometry.size.height * 0.08, 56)))
                    .foregroundStyle(.primary)

                dotsForNumber(card.number)
                    .frame(height: dotsAreaHeight, alignment: .top)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        onSwipeLeft()
                    } else if gesture.translation.width > 50 {
                        onSwipeRight()
                    }
                }
        )
    }

    private func dotsForNumber(_ number: Int) -> some View {
        if number == 0 {
            return AnyView(EmptyView())
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

    private let fontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        GeometryReader { geometry in
            let maxSize = min(geometry.size.width * 0.44, geometry.size.height * 0.48)
            let symbolSize = shapeSymbolSize(maxSize: maxSize)

            VStack(spacing: 28) {
                ShapeSymbolView(kind: card.kind, color: card.color)
                    .frame(width: symbolSize.width, height: symbolSize.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(card.label)
                    .font(.custom(fontName, size: min(geometry.size.height * 0.08, 56)))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        onSwipeLeft()
                    } else if gesture.translation.width > 50 {
                        onSwipeRight()
                    }
                }
        )
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

    private let fontName = "AkzidenzGroteskBE-Bold"

    var body: some View {
        ZStack {
            card.color.ignoresSafeArea()

            GeometryReader { geometry in
                Text(card.label)
                    .font(.custom(fontName, size: min(geometry.size.height * 0.21, geometry.size.width * 0.18)))
                    .foregroundStyle(card.kind.labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, geometry.size.width * 0.08)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        onSwipeLeft()
                    } else if gesture.translation.width > 50 {
                        onSwipeRight()
                    }
                }
        )
    }
}

#endif

#Preview {
    ContentView()
}
