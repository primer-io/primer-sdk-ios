//
//  ConfigurationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Protocol for accessing API configuration in a testable way
@available(iOS 15.0, *)
protocol ConfigurationService {
    /// Get the current API configuration
    var apiConfiguration: PrimerAPIConfiguration? { get }

    /// Get checkout modules from the current configuration
    var checkoutModules: [PrimerAPIConfiguration.CheckoutModule]? { get }

    /// Get billing address options if available
    var billingAddressOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? { get }

    /// Get the current currency from the client session
    var currency: Currency? { get }

    /// Get the current amount from the client session (merchant amount or total order amount)
    var amount: Int? { get }
}

/// Default implementation that wraps access to PrimerAPIConfigurationModule
@available(iOS 15.0, *)
final class DefaultConfigurationService: ConfigurationService {
    var apiConfiguration: PrimerAPIConfiguration? {
        PrimerAPIConfigurationModule.apiConfiguration
    }

    var checkoutModules: [PrimerAPIConfiguration.CheckoutModule]? {
        apiConfiguration?.checkoutModules
    }

    var billingAddressOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? {
        checkoutModules?
            .first(where: { $0.type == "BILLING_ADDRESS" })?
            .options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
    }

    var currency: Currency? {
        apiConfiguration?.clientSession?.order?.currencyCode
    }

    var amount: Int? {
        apiConfiguration?.clientSession?.order?.merchantAmount ??
        apiConfiguration?.clientSession?.order?.totalOrderAmount
    }
}
