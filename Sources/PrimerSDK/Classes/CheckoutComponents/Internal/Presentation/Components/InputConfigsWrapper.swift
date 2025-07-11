//
//  InputConfigsWrapper.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Configuration for card input fields visibility and requirements
@available(iOS 15.0, *)
internal struct CardInputConfiguration {
    let showCardNumber: Bool
    let showCVV: Bool
    let showExpiryDate: Bool
    let showCardholderName: Bool
    let requireCardholderName: Bool

    static let `default` = CardInputConfiguration(
        showCardNumber: true,
        showCVV: true,
        showExpiryDate: true,
        showCardholderName: true,
        requireCardholderName: false
    )
}

/// Wrapper for input field configurations based on backend settings
@available(iOS 15.0, *)
internal struct InputConfigsWrapper {
    let cardInputConfig: CardInputConfiguration
    let billingAddressConfig: BillingAddressConfiguration

    /// Creates input configs from backend payment method configuration
    init(paymentMethodConfig: InternalPaymentMethod?) {
        // Map backend config to field visibility
        // This is where we'd read the backend configuration
        // For now, using defaults

        self.cardInputConfig = .default

        // Determine billing address requirements from backend
        // For now, using minimal config
        self.billingAddressConfig = .minimal
    }

    /// Creates default input configs
    static let `default` = InputConfigsWrapper(
        paymentMethodConfig: nil
    )
}
