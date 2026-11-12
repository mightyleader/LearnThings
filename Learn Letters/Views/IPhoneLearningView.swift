import SwiftUI

struct IPhoneLearningView: View {
    @ObservedObject var speaker: LetterSpeaker
    @Binding var selectedVoiceIdentifier: String
    @Binding var voicesEnabled: Bool

    @State private var path: [AppMode] = []
    @State private var isShowingVoiceSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(AppMode.allCases) { mode in
                        NavigationLink(value: mode) {
                            HStack(spacing: 18) {
                                Image(systemName: mode.systemImage)
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 14))
                                Text(mode.title)
                                    .font(.title2.weight(.semibold))
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.plain)
            #endif
            .navigationTitle("Learn Things")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingVoiceSettings = true
                    } label: {
                        Image(systemName: voicesEnabled ? "speaker.wave.2" : "speaker.slash")
                    }
                    .accessibilityLabel("Voice settings")
                }
            }
            .navigationDestination(for: AppMode.self) { mode in
                if mode == .random {
                    RandomPromptView(onBackToModeSelection: {
                        path.removeLast()
                    })
                } else {
                    IPhoneCardPager(mode: mode, speaker: speaker)
                }
            }
        }
        .sheet(isPresented: $isShowingVoiceSettings) {
            NavigationStack {
                VoiceSelectionView(
                    speaker: speaker,
                    selectedVoiceIdentifier: $selectedVoiceIdentifier,
                    voicesEnabled: $voicesEnabled
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isShowingVoiceSettings = false
                        }
                    }
                }
            }
        }
    }
}

private struct IPhoneCardPager: View {
    let mode: AppMode
    @ObservedObject var speaker: LetterSpeaker

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedIndex = 0
    @State private var isAutoPlaying = false
    @State private var autoPlayTimer: Timer?
    @State private var autoPlayStartedAt: Date?

    private let autoPlayInterval: TimeInterval = 4

    private var cardCount: Int {
        switch mode {
        case .letters: LetterCard.samples.count
        case .numbers: NumberCard.samples.count
        case .shapes: ShapeCard.samples.count
        case .colours: ColourCard.samples.count
        case .random: 0
        }
    }

    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(0..<cardCount, id: \.self) { index in
                card(at: index)
                    .tag(index)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        advance()
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.appBackground)
        .navigationTitle(mode.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    if isAutoPlaying, let autoPlayStartedAt {
                        AutoPlayProgressIndicator(startDate: autoPlayStartedAt, duration: autoPlayInterval, size: 26)
                    }
                    Button(action: toggleAutoPlay) {
                        Image(systemName: isAutoPlaying ? "pause.fill" : "play.fill")
                            .frame(width: 44, height: 44)
                    }
                    .fixedSize()
                    .accessibilityLabel(isAutoPlaying ? "Pause" : "Play")
                }
            }
        }
        .onAppear {
            speak(index: selectedIndex)
        }
        .onDisappear(perform: stopAutoPlay)
        .onChange(of: selectedIndex) { _, newIndex in
            speak(index: newIndex)
            if isAutoPlaying {
                autoPlayStartedAt = Date()
            }
        }
    }

    @ViewBuilder
    private func card(at index: Int) -> some View {
        switch mode {
        case .letters:
            let card = LetterCard.samples[index]
            GeometryReader { geo in
                VStack(spacing: 12) {
                    Text(card.uppercaseLetter)
                        .font(.system(size: geo.size.height * 0.55, weight: .bold, design: .rounded))
                        .foregroundStyle(card.color.adaptedForDarkMode(colorScheme))
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                        .frame(height: geo.size.height * 0.6)
                    Text(card.word)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
        case .numbers:
            let card = NumberCard.samples[index]
            GeometryReader { geo in
                VStack(spacing: 12) {
                    Text(card.displayNumber)
                        .font(.system(size: geo.size.height * 0.45, weight: .bold, design: .rounded))
                        .foregroundStyle(card.color.adaptedForDarkMode(colorScheme))
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                        .frame(height: geo.size.height * 0.5)
                    Text(card.word)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    IPhoneNumberDots(number: card.number, color: card.color.adaptedForDarkMode(colorScheme))
                        .frame(height: 90, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
        case .shapes:
            let card = ShapeCard.samples[index]
            VStack(spacing: 24) {
                ShapeSymbolView(kind: card.kind, color: card.color.adaptedForDarkMode(colorScheme))
                    .frame(maxWidth: 250, maxHeight: 250)
                Text(card.label)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        case .colours:
            let card = ColourCard.samples[index]
            VStack {
                Text(card.label)
                    .font(.system(size: 54, weight: .bold, design: .default))
                    .foregroundStyle(card.kind.labelColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(card.color)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(24)
        case .random:
            EmptyView()
        }
    }

    private func speak(index: Int) {
        guard (0..<cardCount).contains(index) else { return }
        switch mode {
        case .letters:
            speaker.speak(phraseFor: LetterCard.samples[index])
        case .numbers:
            speaker.speak(phraseFor: NumberCard.samples[index])
        case .shapes:
            speaker.speak(phraseFor: ShapeCard.samples[index])
        case .colours:
            speaker.speak(colourFor: ColourCard.samples[index])
        case .random:
            break
        }
    }

    private func toggleAutoPlay() {
        if isAutoPlaying {
            stopAutoPlay()
        } else {
            isAutoPlaying = true
            autoPlayStartedAt = Date()
            autoPlayTimer = Timer.scheduledTimer(withTimeInterval: autoPlayInterval, repeats: true) { _ in
                advance()
            }
        }
    }

    private func advance() {
        guard cardCount > 0 else { return }
        withAnimation {
            selectedIndex = (selectedIndex + 1) % cardCount
        }
    }

    private func stopAutoPlay() {
        isAutoPlaying = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
        autoPlayStartedAt = nil
    }
}

private struct IPhoneNumberDots: View {
    let number: Int
    let color: Color

    var body: some View {
        let perRow = number <= 5 ? max(number, 1) : 5
        let rows = number == 0 ? 0 : (number + perRow - 1) / perRow
        VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<perRow, id: \.self) { col in
                        if row * perRow + col < number {
                            Circle().fill(color).frame(width: 34, height: 34)
                        }
                    }
                }
            }
        }
    }
}
