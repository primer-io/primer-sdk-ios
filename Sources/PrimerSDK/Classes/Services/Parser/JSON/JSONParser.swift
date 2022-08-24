//
//  JSONParser.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
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

extension JSONParser {
    
    func withSnakeCaseParsing() -> JSONParser {
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return self
    }
}

#endif
