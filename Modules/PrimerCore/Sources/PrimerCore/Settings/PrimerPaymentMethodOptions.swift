//
//  PrimerPaymentMethodOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public final class PrimerPaymentMethodOptions: Codable {

    @_spi(PrimerInternal) public let urlScheme: String?
    
    @_spi(PrimerInternal) public let applePayOptions: PrimerApplePayOptions?
    @_spi(PrimerInternal) public let klarnaOptions: PrimerKlarnaOptions?
    @_spi(PrimerInternal) public let threeDsOptions: PrimerThreeDsOptions?
    @_spi(PrimerInternal) public let stripeOptions: PrimerStripeOptions?
        
    // Was producing warning: Immutable property will not be decoded because it is declared with an initial value which cannot be overwritten
    // Was it intentional?
    var cardPaymentOptions: PrimerCardPaymentOptions = PrimerCardPaymentOptions()

    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        threeDsOptions: PrimerThreeDsOptions? = nil,
        stripeOptions: PrimerStripeOptions? = nil
    ) {
        self.urlScheme = urlScheme
        if let urlScheme, URL(string: urlScheme) == nil {
            PrimerLogging.shared.logger.warn(message: """
            The provided url scheme '\(urlScheme)' is not a valid URL. Please ensure that a valid url scheme is provided of the form 'myurlscheme://myapp'
            """)
        }
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
        self.threeDsOptions = threeDsOptions
        self.stripeOptions = stripeOptions
    }

    @available(swift, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        cardPaymentOptions: PrimerCardPaymentOptions? = nil,
        stripeOptions: PrimerStripeOptions? = nil
    ) {
        self.urlScheme = urlScheme
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
        threeDsOptions = nil
        self.stripeOptions = stripeOptions
    }
}
