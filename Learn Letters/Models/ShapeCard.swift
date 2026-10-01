//
//  ShapeCard.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/09/2026.
//

import SwiftUI

enum ShapeKind: String, CaseIterable, Identifiable {
    case circle
    case oval
    case triangle
    case square
    case rectangle
    case diamond
    case arrow
    case heart
    case crescent
    case star
    case cloud
    case pentagon
    case hexagon
    case octagon
    case rhombus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .oval: return "Oval"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .rectangle: return "Rectangle"
        case .diamond: return "Diamond"
        case .arrow: return "Arrow"
        case .heart: return "Heart"
        case .crescent: return "Moon"
        case .star: return "Star"
        case .cloud: return "Cloud"
        case .pentagon: return "Pentagon"
        case .hexagon: return "Hexagon"
        case .octagon: return "Octagon"
        case .rhombus: return "Rhombus"
        }
    }
}

struct ShapeCard: Identifiable {
    let kind: ShapeKind
    let color: Color

    var id: String { kind.rawValue }
    var label: String { kind.displayName }
}

extension ShapeCard {
    static let samples: [ShapeCard] = ShapeKind.allCases.map {
        ShapeCard(kind: $0, color: LearningPalette.color(forShape: $0))
    }
}
