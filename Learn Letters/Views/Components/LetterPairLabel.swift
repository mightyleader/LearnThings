//
//  LetterPairLabel.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI

struct LetterPairLabel: View {
    let uppercase: String
    let lowercase: String
    let separator: String
    let uppercaseColor: Color
    let lowercaseColor: Color
    let font: Font
    let minimumScaleFactor: CGFloat
    let horizontalInset: CGFloat

    var body: some View {
        Text(styledLabel)
            .font(font)
            .lineLimit(1)
            .minimumScaleFactor(minimumScaleFactor)
            .multilineTextAlignment(.center)
            .padding(.horizontal, horizontalInset)
    }

    private var styledLabel: AttributedString {
        var value = AttributedString(uppercase)
        value.foregroundColor = uppercaseColor

        var lower = AttributedString(separator + lowercase)
        lower.foregroundColor = lowercaseColor

        value.append(lower)
        return value
    }
}
