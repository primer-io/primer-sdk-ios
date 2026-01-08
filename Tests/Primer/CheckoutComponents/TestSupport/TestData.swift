//
//  TestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Centralized test data for CheckoutComponents tests.
/// All test data is organized by category for easy discovery and use.
@available(iOS 15.0, *)
enum TestData {

    // MARK: - Tokens

    enum Tokens {
        static let valid = "test-token"
    }

    // MARK: - Payment Amounts

    enum Amounts {
        static let standard = 1000          // $10.00
    }

    // MARK: - Currencies

    enum Currencies {
        static let usd = "USD"
        static let defaultDecimalDigits = 2
    }
}
