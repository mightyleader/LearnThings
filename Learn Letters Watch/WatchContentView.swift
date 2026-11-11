import SwiftUI

struct WatchContentView: View {
    var body: some View {
        NavigationStack {
            List(WatchLearningMode.allCases) { mode in
                NavigationLink(value: mode) {
                    Label(mode.title, systemImage: mode.systemImage)
                }
            }
            .navigationTitle("Learn")
            .navigationDestination(for: WatchLearningMode.self) { mode in
                WatchCardBrowser(mode: mode)
            }
        }
    }
}

private struct WatchCardBrowser: View {
    let mode: WatchLearningMode
    @State private var crownValue = 0.0

    private var cards: [WatchLearningCard] {
        mode.cards
    }

    private var selectedIndex: Int {
        min(max(Int(crownValue.rounded()), 0), cards.count - 1)
    }

    var body: some View {
        let card = cards[selectedIndex]

        Group {
            if case .swatch(let color) = card.visual {
                ZStack {
                    color.ignoresSafeArea()
                    Text(card.word)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(card.labelColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                }
            } else {
                VStack(spacing: 4) {
                    cardContent(card)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text(card.word)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: Double(max(cards.count - 1, 0)),
            by: 1.0,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }

    @ViewBuilder
    private func cardContent(_ card: WatchLearningCard) -> some View {
        switch card.visual {
        case .text(let value):
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 160, weight: .bold, design: .rounded))
                    .foregroundStyle(card.color)
                    .minimumScaleFactor(0.2)
                    .lineLimit(1)
                if let count = card.dotCount, count > 0 {
                    WatchNumberDots(number: count, color: card.color)
                }
            }
        case .symbol(let name):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .foregroundStyle(card.color)
                .padding(4)
        case .swatch:
            EmptyView()
        }
    }
}

private struct WatchNumberDots: View {
    let number: Int
    let color: Color

    var body: some View {
        let perRow = number <= 5 ? number : 5
        let rows = (number + perRow - 1) / perRow
        VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<perRow, id: \.self) { col in
                        if row * perRow + col < number {
                            Circle().fill(color).frame(width: 9, height: 9)
                        }
                    }
                }
            }
        }
    }
}

private enum WatchLearningMode: String, CaseIterable, Identifiable, Hashable {
    case letters
    case numbers
    case shapes
    case colours

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .letters: "textformat.alt"
        case .numbers: "textformat.numbers"
        case .shapes: "square.on.circle"
        case .colours: "rainbow"
        }
    }

    var cards: [WatchLearningCard] {
        switch self {
        case .letters:
            LetterCard.samples.map {
                WatchLearningCard(
                    id: $0.id,
                    word: $0.word,
                    visual: .text($0.uppercaseLetter),
                    color: $0.color
                )
            }
        case .numbers:
            NumberCard.samples.map {
                WatchLearningCard(
                    id: $0.id,
                    word: $0.word,
                    visual: .text($0.displayNumber),
                    color: $0.color,
                    dotCount: $0.number
                )
            }
        case .shapes:
            ShapeCard.samples.map {
                WatchLearningCard(
                    id: $0.id,
                    word: $0.label,
                    visual: .symbol(symbol(for: $0.kind)),
                    color: $0.color
                )
            }
        case .colours:
            ColourCard.samples.map {
                WatchLearningCard(
                    id: $0.id,
                    word: $0.label,
                    visual: .swatch($0.color),
                    color: $0.color,
                    labelColor: $0.kind.labelColor
                )
            }
        }
    }

    private func symbol(for shape: ShapeKind) -> String {
        switch shape {
        case .circle: "circle"
        case .oval: "oval"
        case .triangle: "triangle"
        case .square: "square"
        case .rectangle: "rectangle"
        case .diamond, .rhombus: "rhombus"
        case .arrow: "arrow.right"
        case .heart: "heart.fill"
        case .crescent: "moon.fill"
        case .star: "star.fill"
        case .cloud: "cloud.fill"
        case .pentagon: "pentagon"
        case .hexagon: "hexagon"
        case .octagon: "octagon"
        }
    }
}

private struct WatchLearningCard: Identifiable {
    enum Visual {
        case text(String)
        case symbol(String)
        case swatch(Color)
    }

    let id: String
    let word: String
    let visual: Visual
    let color: Color
    var dotCount: Int? = nil
    var labelColor: Color = .primary
}
