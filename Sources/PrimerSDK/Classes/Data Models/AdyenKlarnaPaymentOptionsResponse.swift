//
//  AdyenKlarnaPaymentOptionsResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct AdyenKlarnaPaymentOptionsResponse: Decodable {
    let result: [AdyenKlarnaPaymentOptionDTO]
}

struct AdyenKlarnaPaymentOptionDTO: Decodable {
    let id: String
    let name: String
}
