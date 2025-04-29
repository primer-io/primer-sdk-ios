//
//  CardNumberCursorManager.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import Foundation

public class CardNumberCursorManager: CursorPositionManaging {
    public init() {}
    public func position(for raw: String, formatted: String, original: Int) -> Int {
        // Map digit index to formatted position
        let rawDigits = raw.filter { $0.isNumber }
        var digitCount = 0, pos = 0
        for char in formatted {
            if digitCount == original { break }
            if char.isNumber { digitCount += 1 }
            pos += 1
        }
        return pos
    }
}