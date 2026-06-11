//
//  XenditRetailOutlets.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

// swiftlint:disable:next type_name
struct RetailOutletTokenizationSessionRequestParameters: OffSessionPaymentSessionInfo {
    let locale: String = PrimerSettings.current.localeData.localeCode
    let platform: String = "IOS"
    let retailOutlet: String
}

@objc public final class RetailOutletsList: PrimerInitializationData {

    public let result: [RetailOutletsRetail]

    private enum CodingKeys: String, CodingKey {
        case result
    }

    init(result: [RetailOutletsRetail]) {
        self.result = result
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode([RetailOutletsRetail].self, forKey: .result)
        super.init()
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(result, forKey: .result)
    }
}
