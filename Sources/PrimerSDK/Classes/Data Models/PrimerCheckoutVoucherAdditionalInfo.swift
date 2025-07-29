//
//  PrimerCheckoutVoucherAdditionalInfo.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@objc public class PrimerCheckoutVoucherAdditionalInfo: PrimerCheckoutAdditionalInfo {}

@objc public final class XenditCheckoutVoucherAdditionalInfo: PrimerCheckoutVoucherAdditionalInfo {

    public let expiresAt: String
    public let couponCode: String
    public let retailerName: String

    private enum CodingKeys: String, CodingKey {
        case expiresAt
        case couponCode
        case retailerName
    }

    public init(expiresAt: String, couponCode: String, retailerName: String) {
        self.expiresAt = expiresAt
        self.couponCode = couponCode
        self.retailerName = retailerName
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiresAt = try container.decode(String.self, forKey: .expiresAt)
        couponCode = try container.decode(String.self, forKey: .couponCode)
        retailerName = try container.decode(String.self, forKey: .retailerName)
        super.init()
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(couponCode, forKey: .couponCode)
        try container.encode(retailerName, forKey: .retailerName)
    }
}
