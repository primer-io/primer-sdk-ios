//
//  TestData+PaymentMethods.swift
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

    // MARK: - Payment Method Identifiers

    enum PaymentMethodIds {
        static let cardId = "card-pm-id"
        static let paypalId = "paypal-pm-id"
        static let applePayId = "apple-pay-pm-id"
        static let googlePayId = "google-pay-pm-id"
    }

    // MARK: - Payment Method Names

    enum PaymentMethodNames {
        static let cardName = "Card"
        static let paypalName = "PayPal"
        static let applePayName = "Apple Pay"
        static let googlePayName = "Google Pay"
    }

    // MARK: - Payment Method Options

    enum PaymentMethodOptions {
        static let monthlySubscription = "Monthly subscription"
        static let testSubscription = "Test Subscription"
        static let subscription = "Subscription"
        static let exampleMerchantId = "merchant.com.example.app"
        static let testMerchantId = "merchant.test"
        static let testMerchantName = "Test Merchant"
        static let myAppUrlScheme = "myapp://payment"
        static let testAppUrl = "testapp://payment"
        static let testAppUrlTrailing = "testapp://"
        static let testAppScheme = "testapp"
        static let myAppScheme = "myapp"
    }

    // MARK: - Payment IDs

    enum PaymentIds {
        static let success = "test-payment-123"
        static let pending = "test-payment-456"
        static let failed = "test-payment-789"
    }
}
