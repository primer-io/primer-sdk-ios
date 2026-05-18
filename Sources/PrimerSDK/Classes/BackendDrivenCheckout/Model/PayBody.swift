//
//  PayBody.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct PayBody: Encodable {
    let paymentMethodConfigId: String?
    let processorMerchantAccountId: String
    let paymentMethodType: String
    
    private let clientInfo = ClientInfo(
        merchant: ClientSessionMerchantDataRequest(
            applicationId: Bundle.main.bundleIdentifier
        )
    )
}

private struct ClientInfo: Encodable {
    fileprivate let locale = PrimerSettings.current.localeData.localeCode
    fileprivate let platform = "IOS"
    fileprivate let returnUri = try? PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme()
    fileprivate let merchant: ClientSessionMerchantDataRequest
}

private struct ClientSessionMerchantDataRequest: Encodable {
    let applicationId: String?
}
