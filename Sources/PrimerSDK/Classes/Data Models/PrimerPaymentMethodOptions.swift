//
//  PrimerPaymentMethodOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  PrimerPaymentMethodOptions.swift
//  
//
//  Created by Henry Cooper on 27/05/2026.
//
import Foundation

public final class PrimerPaymentMethodOptions: PrimerPaymentMethodOptionsProtocol, Codable {

    private let urlScheme: String?
    let applePayOptions: PrimerApplePayOptions?
    var klarnaOptions: PrimerKlarnaOptions?

    // Was producing warning: Immutable property will not be decoded because it is declared with an initial value which cannot be overwritten
    // Was it intentional?
    var cardPaymentOptions: PrimerCardPaymentOptions = PrimerCardPaymentOptions()
    var threeDsOptions: PrimerThreeDsOptions?
    var stripeOptions: PrimerStripeOptions?

    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        threeDsOptions: PrimerThreeDsOptions? = nil,
        stripeOptions: PrimerStripeOptions? = nil
    ) {
        self.urlScheme = urlScheme
        if let urlScheme = urlScheme, URL(string: urlScheme) == nil {
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
        self.stripeOptions = stripeOptions
    }

    func validUrlForUrlScheme() throws -> URL {
        guard let urlScheme = urlScheme, let url = URL(string: urlScheme), url.scheme != nil else {
            throw handled(primerError: .invalidValue(key: "urlScheme"))
        }
        return url
    }

    func validSchemeForUrlScheme() throws -> String {
        let url = try validUrlForUrlScheme()
        guard let scheme = url.scheme else { throw handled(primerError: .invalidValue(key: "urlScheme")) }
        return scheme
    }
}
