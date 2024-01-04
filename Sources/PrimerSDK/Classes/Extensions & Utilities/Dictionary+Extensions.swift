//
//  Dictionary+Extensions.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 02/01/2024.
//

import Foundation

extension Dictionary<String, String> {
    static func errorUserInfoDictionary(
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line
    ) -> [String: String] {
        return [
            "file": "\(file)",
            "class": "\(Self.self)",
            "function": "\(function)",
            "line": "\(line)"
        ]
    }
}
