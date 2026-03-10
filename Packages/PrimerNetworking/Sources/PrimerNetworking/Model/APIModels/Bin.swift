//
//  Bin.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Response.Body {
    public struct Bin {}
}

extension Response.Body.Bin {
    public struct Networks: Decodable {
        public let networks: [Network]

        init(networks: [Network]) {
            self.networks = networks
        }
    }
}

extension Response.Body.Bin.Networks {
    public struct Network: Decodable {
        public let value: String

        init(value: String) {
            self.value = value
        }
    }
}

extension Response.Body.Bin {
    public struct Data: Decodable {
        public let firstDigits: String?
        public let binData: [BinDataItem]

        init(firstDigits: String?, binData: [BinDataItem]) {
            self.firstDigits = firstDigits
            self.binData = binData
        }
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

        init(
            displayName: String? = nil,
            network: String? = nil,
            issuerCountryCode: String? = nil,
            issuerName: String? = nil,
            accountFundingType: String? = nil,
            prepaidReloadableIndicator: String? = nil,
            productUsageType: String? = nil,
            productCode: String? = nil,
            productName: String? = nil,
            issuerCurrencyCode: String? = nil,
            regionalRestriction: String? = nil,
            accountNumberType: String? = nil
        ) {
            self.displayName = displayName
            self.network = network
            self.issuerCountryCode = issuerCountryCode
            self.issuerName = issuerName
            self.accountFundingType = accountFundingType
            self.prepaidReloadableIndicator = prepaidReloadableIndicator
            self.productUsageType = productUsageType
            self.productCode = productCode
            self.productName = productName
            self.issuerCurrencyCode = issuerCurrencyCode
            self.regionalRestriction = regionalRestriction
            self.accountNumberType = accountNumberType
        }
    }
}

extension Response.Body.Bin.Networks {
    public init(from binData: Response.Body.Bin.Data) {
        networks = binData.binData.compactMap(\.network).map(Network.init(value:))
    }
}
