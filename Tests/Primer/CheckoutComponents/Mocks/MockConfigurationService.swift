//
//  MockConfigurationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of ConfigurationService for testing
@available(iOS 15.0, *)
final class MockConfigurationService: ConfigurationService {

    // MARK: - Configurable Return Values

    var apiConfiguration: PrimerAPIConfiguration?
    var checkoutModules: [PrimerAPIConfiguration.CheckoutModule]?
    var billingAddressOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions?
    var currency: Currency?
    var amount: Int?

    // MARK: - Initialization

    init(
        apiConfiguration: PrimerAPIConfiguration? = nil,
        checkoutModules: [PrimerAPIConfiguration.CheckoutModule]? = nil,
        billingAddressOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? = nil,
        currency: Currency? = nil,
        amount: Int? = nil
    ) {
        self.apiConfiguration = apiConfiguration
        self.checkoutModules = checkoutModules
        self.billingAddressOptions = billingAddressOptions
        self.currency = currency
        self.amount = amount
    }

    // MARK: - Test Helpers

    func reset() {
        apiConfiguration = nil
        checkoutModules = nil
        billingAddressOptions = nil
        currency = nil
        amount = nil
    }

    /// Creates a mock with default USD configuration
    static func withDefaultConfiguration() -> MockConfigurationService {
        let mock = MockConfigurationService()
        mock.currency = Currency(code: "USD", decimalDigits: 2)
        mock.amount = 1000  // $10.00 in cents
        return mock
    }
}
