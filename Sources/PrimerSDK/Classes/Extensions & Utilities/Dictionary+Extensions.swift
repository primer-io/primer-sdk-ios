//
//  Dictionary+Extensions.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import struct Swift.Dictionary

public extension [String: String] {
    static func errorUserInfoDictionary<T>(
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        type: T.Type = Self.self,
        additionalInfo: [String: String] = [:]
    ) -> [String: String] {
        var dict = [
            "file": "\(file)",
            "class": "\(type)",
            "function": "\(function)",
            "line": "\(line)"
        ]

        for (key, value) in additionalInfo {
            dict[key] = value
        }

        return dict
    }
}
