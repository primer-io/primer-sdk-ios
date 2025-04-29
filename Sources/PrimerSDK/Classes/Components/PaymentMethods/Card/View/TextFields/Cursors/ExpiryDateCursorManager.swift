//
//  ExpiryDateCursorManager.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class ExpiryDateCursorManager: CursorPositionManaging {
    public init() {}
    public func position(for raw: String, formatted: String, original: Int) -> Int {
        // Place slash after 2 digits
        if original <= 2 { return original }
        return min(original + 1, formatted.count)
    }
}
