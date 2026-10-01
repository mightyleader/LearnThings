//
//  NumberCard.swift
//  Learn Things
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct NumberCard: Identifiable {
    let number: Int
    let word: String
    let color: Color

    var id: String { String(number) }
    var displayNumber: String { String(number) }
}

extension NumberCard {

    // MARK: - Fallback data (used if text files are missing or incomplete)

    private static let fallbackWords: [Int: String] = [
        0: "Zero", 1: "One", 2: "Two", 3: "Three", 4: "Four",
        5: "Five", 6: "Six", 7: "Seven", 8: "Eight", 9: "Nine",
        10: "Ten"
    ]

    // MARK: - Card factory

    static let samples: [NumberCard] = {
        let numbers = Array(0...10)
        
        return numbers.map { number in
            let word  = fallbackWords[number] ?? String(number)
            let color = LearningPalette.color(forNumber: number)
            return NumberCard(number: number, word: word, color: color)
        }
    }()
}
