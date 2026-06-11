//
//  Bin.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Response.Body {
    @_spi(PrimerInternal) public struct Bin {}
}

extension Response.Body.Bin {
    public struct Networks: Decodable {
        public let networks: [Network]
    }
}

extension Response.Body.Bin.Networks {
    public struct Network: Decodable {
        public let value: String
    }
}

extension Response.Body.Bin {
    public struct Data: Decodable {
        public let firstDigits: String?
        public let binData: [BinDataItem]
    }
}

extension Response.Body.Bin.Data {
    public struct BinDataItem: Decodable {
        public let displayName: String?
        public let network: String?
        public let issuerCountryCode: String?
        public let issuerName: String?
        public let accountFundingType: String?
        public let prepaidReloadableIndicator: String?
        public let productUsageType: String?
        public let productCode: String?
        public let productName: String?
        public let issuerCurrencyCode: String?
        public let regionalRestriction: String?
        public let accountNumberType: String?
    }
}

@_spi(PrimerInternal) public extension Response.Body.Bin.Networks {
    init(from binData: Response.Body.Bin.Data) {
        networks = binData.binData.compactMap(\.network).map(Network.init(value:))
    }
}
