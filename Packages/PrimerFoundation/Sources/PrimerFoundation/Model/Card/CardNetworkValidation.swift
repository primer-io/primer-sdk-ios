//
//  CardNetworkValidation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Validation rules for a card network
public struct CardNetworkValidation: Sendable {
    /// Human-readable name for the card network
    public let niceType: String
    
    /// BIN ranges that identify this card network
    /// Each pattern is an array of 1-2 integers representing a range
    /// [min] or [min, max]
    public let patterns: [[Int]]
    
    /// Character positions where spacing should be inserted when formatting
    public let gaps: [Int]
    
    /// Valid card number lengths for this network
    public let lengths: [Int]
    
    /// Security code validation
    public let code: CardNetworkCode
    
    public init(
        niceType: String,
        patterns: [[Int]],
        gaps: [Int],
        lengths: [Int],
        code: CardNetworkCode
    ) {
        self.niceType = niceType
        self.patterns = patterns
        self.gaps = gaps
        self.lengths = lengths
        self.code = code
    }
}

/// Security code (CVV/CVC/CID) validation rules
public struct CardNetworkCode: Sendable {
    /// Name of the security code (CVV, CVC, CID, etc.)
    public let name: String
    
    /// Expected length of the security code
    public let length: Int
    
    public init(name: String, length: Int) {
        self.name = name
        self.length = length
    }
}
