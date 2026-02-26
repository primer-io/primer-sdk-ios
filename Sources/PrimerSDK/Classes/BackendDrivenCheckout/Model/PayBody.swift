//
//  PayBody.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

struct PayBody {
    let paymentMethodConfigId: String?
    let processorMerchantAccountId: String
    let paymentMethodType = "ADYEN_IDEAL"
    
    private let clientInfo = ClientInfo()
}

private struct ClientInfo: Encodable {
    private let locale = PrimerSettings.current.localeData.localeCode
    private let platform = "IOS"
    private let redirectionUrl = try! PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
}

extension PayBody: Encodable {}
