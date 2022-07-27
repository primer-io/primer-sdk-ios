//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

internal class JSONParser: Parser {
    private let jsonDecoder = JSONDecoder()

    func parse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try jsonDecoder.decode(T.self, from: data)
    }
}

extension JSONParser {
    
    func loadJsonData(fileName: String) -> Data? {
        
        guard let url = Bundle.primerResources.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        
        return try? Data(contentsOf: url)
    }
}

#endif
