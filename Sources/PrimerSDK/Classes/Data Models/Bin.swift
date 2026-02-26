//
//  Bin.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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

extension Response.Body.Bin {
    struct Data: Decodable {
        let firstDigits: String?
        let binData: [BinDataItem]
    }
}

extension Response.Body.Bin.Data {
    struct BinDataItem: Decodable {
        let displayName: String?
        let network: String?
        let issuerCountryCode: String?
        let issuerName: String?
        let accountFundingType: String?
        let prepaidReloadableIndicator: String?
        let productUsageType: String?
        let productCode: String?
        let productName: String?
        let issuerCurrencyCode: String?
        let regionalRestriction: String?
        let accountNumberType: String?
    }
}

extension Response.Body.Bin.Networks {
    init(from binData: Response.Body.Bin.Data) {
        networks = binData.binData.compactMap(\.network).map(Network.init(value:))
    }
}
