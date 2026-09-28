//
//  SDKContext+Checkout.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

extension SDKContext {
    /// The checkout's context; flows add `payment`.
    static func checkout(payment: SDKPayment? = nil) -> SDKContext {
        let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration
        return SDKContext(
            sdk: SDK(),
            device: SDKDevice(),
            app: SDKApp(identifier: Bundle.primerFrameworkIdentifier),
            session: SDKSession(configuration: apiConfiguration, sessionId: PrimerInternal.shared.checkoutSessionId),
            payment: payment,
            merchant: SDKMerchant(primerAccountId: apiConfiguration?.primerAccountId),
            // Not `validUrlForUrlScheme()`, which reports a missing scheme as an error.
            redirect: SDKRedirect(urlScheme: PrimerSettings.current.paymentMethodOptions.urlScheme),
            analytics: SDKAnalytics(url: PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2)
        )
    }
}
