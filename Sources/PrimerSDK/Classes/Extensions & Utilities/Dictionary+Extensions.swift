//
//  Dictionary+Extensions.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 02/01/2024.
//

import Foundation

extension Dictionary<String, String> {
    static func errorUserInfoDictionary<T>(
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        type: T.Type = Self.self
    ) -> [String: String] {
        return [
            "file": "\(file)",
            "class": "\(type)",
            "function": "\(function)",
            "line": "\(line)"
        ]
    }
}
