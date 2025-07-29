//
//  Parser.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal protocol Parser {
    func parse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
