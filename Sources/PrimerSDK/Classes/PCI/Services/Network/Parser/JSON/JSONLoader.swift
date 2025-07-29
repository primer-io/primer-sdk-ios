//
//  JSONLoader.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

final class JSONLoader {

    static func loadJsonData(fileName: String) -> Data? {

        guard let url = Bundle.primerResources.url(forResource: fileName, withExtension: "json") else {
            return nil
        }

        return try? Data(contentsOf: url)
    }
}

extension JSONDecoder {

    func withSnakeCaseParsing() -> JSONDecoder {
        self.keyDecodingStrategy = .convertFromSnakeCase
        return self
    }
}
