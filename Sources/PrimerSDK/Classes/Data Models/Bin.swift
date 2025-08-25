//
//  Bin.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Response.Body {
    struct Bin {}
}

extension Response.Body.Bin {
    struct Networks: Decodable {
        let networks: [Network]
    }
}

extension Response.Body.Bin.Networks {
    struct Network: Decodable {
        let value: String
    }
}
