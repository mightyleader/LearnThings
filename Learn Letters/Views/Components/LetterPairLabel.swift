//
//  LetterPairLabel.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import SwiftUI
import UIKit

struct LetterPairLabel: UIViewRepresentable {
    let uppercase: String
    let lowercase: String
    let separator: String
    let uppercaseColor: UIColor
    let lowercaseColor: UIColor
    let font: UIFont
    let minimumScaleFactor: CGFloat
    let horizontalInset: CGFloat

    func makeUIView(context: Context) -> InsetLabel {
        let label = InsetLabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        label.lineBreakMode = .byClipping
        label.clipsToBounds = false
        return label
    }

    func updateUIView(_ label: InsetLabel, context: Context) {
        label.minimumScaleFactor = minimumScaleFactor
        label.textInsets = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)

        let text = NSMutableAttributedString(
            string: uppercase,
            attributes: [
                .font: font,
                .foregroundColor: uppercaseColor
            ]
        )
        text.append(
            NSAttributedString(
                string: separator + lowercase,
                attributes: [
                    .font: font,
                    .foregroundColor: lowercaseColor
                ]
            )
        )

        label.attributedText = text
    }
}

final class InsetLabel: UILabel {
    var textInsets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
