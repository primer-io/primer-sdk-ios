//
//  TestData+Navigation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Payment Method Types

    enum PaymentMethodTypes {
        static let card = "PAYMENT_CARD"
        static let applePay = "APPLE_PAY"
        static let paypal = "PAYPAL"
        static let klarna = "KLARNA"
    }

    // MARK: - Payment IDs

    enum PaymentIds {
        static let success = "test-payment-123"
        static let pending = "test-payment-456"
        static let failed = "test-payment-789"
    }

    // MARK: - Formatted Amounts

    enum FormattedAmounts {
        static let tenDollars = "$10.00"
        static let oneDollar = "$1.00"
        static let hundredDollars = "$100.00"
    }

    // MARK: - Error Keys

    enum ErrorKeys {
        static let test = "test-error-key"
        static let cardNumber = "cardNumber"
        static let expiry = "expiry"
        static let cvv = "cvv"
    }

    // MARK: - Diagnostics IDs

    enum DiagnosticsIds {
        static let test = "test-diagnostics-123"
        static let validation = "validation-diagnostics-456"
    }
}
