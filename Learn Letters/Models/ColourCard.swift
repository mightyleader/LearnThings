//
//  ColourCard.swift
//  Learn Things
//

import SwiftUI

enum ColourKind: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, blue, purple, pink, grey, black, white

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var labelColor: Color {
        switch self {
        case .red, .orange, .green, .blue, .purple, .black:
            return .white
        case .yellow, .pink, .grey, .white:
            return .black
        }
    }
}

struct ColourCard: Identifiable {
    let kind: ColourKind
    let color: Color

    var id: String { kind.id }
    var label: String { kind.name }

    static let samples: [ColourCard] = ColourKind.allCases.map {
        ColourCard(kind: $0, color: LearningPalette.color(forColour: $0))
    }
}
