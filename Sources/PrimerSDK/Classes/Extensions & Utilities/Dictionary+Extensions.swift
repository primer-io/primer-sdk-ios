//
//  Dictionary+Extensions.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 02/01/2024.
//

import Foundation

extension Optional<Dictionary<String, String>> {
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
