//
//  TestData+Payments.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Payment Amounts

    enum Amounts {
        static let standard = 1000          // $10.00
        static let small = 100              // $1.00
        static let large = 100000           // $1,000.00
        static let withSurcharge = 2000     // $20.00
        static let zero = 0
    }

    // MARK: - Currencies

    enum Currencies {
        static let usd = "USD"
        static let eur = "EUR"
        static let gbp = "GBP"
        static let jpy = "JPY"
        static let defaultDecimalDigits = 2
    }

    // MARK: - Payment Results

    /// Payment processing outcome fixtures
    enum PaymentResults {
        /// Successful payment completion
        static let success = (
            status: "success",
            transactionId: "test-payment-123",
            error: nil as Error?,
            threeDSRequired: false,
            surchargeAmount: nil as Int?
        )

        /// Payment requires 3DS challenge
        static let threeDSRequired = (
            status: "pending",
            transactionId: "test-payment-456",
            error: nil as Error?,
            threeDSRequired: true,
            surchargeAmount: nil as Int?
        )

        /// Payment declined by issuer
        static let declined = (
            status: "failure",
            transactionId: nil as String?,
            error: NSError(
                domain: "PaymentError",
                code: 402,
                userInfo: [NSLocalizedDescriptionKey: "Payment declined: Insufficient funds"]
            ) as Error,
            threeDSRequired: false,
            surchargeAmount: nil as Int?
        )

        /// Payment with network surcharge
        static let withSurcharge = (
            status: "success",
            transactionId: "test-payment-789",
            error: nil as Error?,
            threeDSRequired: false,
            surchargeAmount: 50 as Int? // 50 cents
        )

        /// Payment cancelled by user
        static let cancelled = (
            status: "cancelled",
            transactionId: nil as String?,
            error: NSError(
                domain: "PaymentError",
                code: -999,
                userInfo: [NSLocalizedDescriptionKey: "Payment cancelled by user"]
            ) as Error,
            threeDSRequired: false,
            surchargeAmount: nil as Int?
        )
    }

    // MARK: - 3DS Flows

    /// 3D Secure challenge scenario fixtures
    enum ThreeDSFlows {
        /// Challenge required - user must complete 3DS authentication
        static let challengeRequired = (
            transactionId: "test-tx-123",
            acsTransactionId: "test-acs-456",
            acsReferenceNumber: "test-ref-789",
            acsSignedContent: "signed-content-challenge",
            challengeRequired: true,
            outcome: "success"
        )

        /// Frictionless flow - 3DS completed without user interaction
        static let frictionless = (
            transactionId: "test-tx-234",
            acsTransactionId: "test-acs-567",
            acsReferenceNumber: "test-ref-890",
            acsSignedContent: nil as String?,
            challengeRequired: false,
            outcome: "success"
        )

        /// Failed 3DS authentication
        static let failed = (
            transactionId: "test-tx-345",
            acsTransactionId: "test-acs-678",
            acsReferenceNumber: "test-ref-901",
            acsSignedContent: "signed-content-failed",
            challengeRequired: true,
            outcome: "failure"
        )

        /// User cancelled 3DS challenge
        static let cancelled = (
            transactionId: "test-tx-456",
            acsTransactionId: "test-acs-789",
            acsReferenceNumber: "test-ref-012",
            acsSignedContent: "signed-content-cancelled",
            challengeRequired: true,
            outcome: "cancelled"
        )

        /// 3DS challenge timed out
        static let timeout = (
            transactionId: "test-tx-567",
            acsTransactionId: "test-acs-890",
            acsReferenceNumber: "test-ref-123",
            acsSignedContent: "signed-content-timeout",
            challengeRequired: true,
            outcome: "timeout"
        )
    }
}
