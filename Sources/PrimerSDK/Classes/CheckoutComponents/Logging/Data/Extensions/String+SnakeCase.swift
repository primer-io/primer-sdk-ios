//
//  String+SnakeCase.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension String {
    func toSnakeCase() -> String {
        guard !isEmpty else { return self }

        var result = ""
        for (index, character) in enumerated() {
            if character.isUppercase {
                if index > 0 {
                    result += "_"
                }
                result += character.lowercased()
            } else {
                result += String(character)
            }
        }
        return result
    }
}
