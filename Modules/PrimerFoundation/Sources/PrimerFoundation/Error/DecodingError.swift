//
//  DecodingError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

extension DecodingError {
    static func unexpectedValue(type: Any.Type, decoder: Decoder) -> DecodingError {
        .typeMismatch(type, decoder.unexpectedValueContext)
    }
}

private extension Decoder {
    var unexpectedValueContext: DecodingError.Context {
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Unexpected value"
        )
    }
}
