//
//  CardNetworkValidation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct CardNetworkValidation: Sendable {
    public let niceType: String
    public let patterns: [[Int]]
    public let gaps: [Int]
    public let lengths: [Int]
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

public struct CardNetworkCode: Sendable {
    public let name: String
    public let length: Int
    
    public init(name: String, length: Int) {
        self.name = name
        self.length = length
    }
}
