//
//  Dictionary.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension Dictionary {
    func data(options: JSONSerialization.WritingOptions = []) throws -> Data {
		try JSONSerialization.data(withJSONObject: self, options: options)
	}
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        String(data: try data(), encoding: encoding)
    }
}

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
