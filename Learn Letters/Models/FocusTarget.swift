//
//  FocusTarget.swift
//  Learn Letters
//
//  Created by Rob Stearn on 30/06/2026.
//

import Foundation

enum FocusTarget: Hashable {
    case hero
    case tile(String) // String representation of tile ID (letter or number)
}
