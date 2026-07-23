//
//  RawPaymentInstrument.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

struct RawPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    let json: CodableValue

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(json)
    }
}
