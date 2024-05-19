//
//  JSONLoader.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

class JSONLoader {

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
