//
//  Range+Extensions.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Range where Bound == String.Index {
    func toNSRange(in text: String) -> NSRange {
        return NSRange(self, in: text)
    }
}
