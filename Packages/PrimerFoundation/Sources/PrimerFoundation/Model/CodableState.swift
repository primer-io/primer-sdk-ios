//
//  CodableState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public typealias CodableState = [String: CodableValue]

public extension CodableState {
    init(_ dict: [String: Any]) throws {
        self = try JSONDecoder().decode([String: CodableValue].self, from: dict.data())
    }
}
