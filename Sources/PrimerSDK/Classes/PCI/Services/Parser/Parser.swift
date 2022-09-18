//
//  Parser.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

internal protocol Parser {
    func parse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

#endif
