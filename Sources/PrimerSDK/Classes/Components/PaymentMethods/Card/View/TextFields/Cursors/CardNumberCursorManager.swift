//
//  CardNumberCursorManager.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class CardNumberCursorManager: CursorPositionManaging {
    public init() {}

    /// Returns the cursor position in the *formatted* string
    /// corresponding to the `original` digit index in the raw input.
    public func position(for raw: String, formatted: String, original: Int) -> Int {
        var digitCount = 0 // how many numeric characters we’ve seen so far
        var pos = 0 // current index in `formatted`

        for char in formatted {
            // once we’ve reached the desired digit index, stop
            if digitCount == original { break }

            if char.isNumber {
                digitCount += 1
            }
            pos += 1
        }

        return pos
    }
}
