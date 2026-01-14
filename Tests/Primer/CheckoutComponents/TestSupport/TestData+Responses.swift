//
//  TestData+Responses.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
extension TestData {

    // MARK: - API Responses

    enum APIResponses {
        static let validPaymentMethods = """
        {
            "paymentMethods": [
                {
                    "id": "PAYMENT_CARD",
                    "type": "PAYMENT_CARD",
                    "name": "Card",
                    "isEnabled": true,
                    "supportedCardNetworks": ["VISA", "MASTERCARD", "AMEX"]
                }
            ]
        }
        """

        static let emptyPaymentMethods = """
        {
            "paymentMethods": []
        }
        """

        static let malformedJSON = "{invalid json}"

        static let merchantConfig = """
        {
            "merchantId": "test-merchant-123",
            "settings": {
                "theme": "light",
                "enableAnalytics": true
            }
        }
        """

        static let errorResponse = """
        {
            "error": {
                "code": "PAYMENT_DECLINED",
                "message": "Insufficient funds"
            }
        }
        """
    }

    // MARK: - Payment Results

    enum PaymentResults {
        static let success = (
            status: "success",
            transactionId: "test-payment-123",
            error: nil as Error?,
            threeDSRequired: false,
            surchargeAmount: nil as Int?
        )

        static let threeDSRequired = (
            status: "pending",
            transactionId: "test-payment-456",
            error: nil as Error?,
            threeDSRequired: true,
            surchargeAmount: nil as Int?
        )

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

        static let withSurcharge = (
            status: "success",
            transactionId: "test-payment-789",
            error: nil as Error?,
            threeDSRequired: false,
            surchargeAmount: 50 as Int?
        )

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

    enum ThreeDSFlows {
        static let challengeRequired = (
            transactionId: "test-tx-123",
            acsTransactionId: "test-acs-456",
            acsReferenceNumber: "test-ref-789",
            acsSignedContent: "signed-content-challenge",
            challengeRequired: true,
            outcome: "success"
        )

        static let frictionless = (
            transactionId: "test-tx-234",
            acsTransactionId: "test-acs-567",
            acsReferenceNumber: "test-ref-890",
            acsSignedContent: nil as String?,
            challengeRequired: false,
            outcome: "success"
        )

        static let failed = (
            transactionId: "test-tx-345",
            acsTransactionId: "test-acs-678",
            acsReferenceNumber: "test-ref-901",
            acsSignedContent: "signed-content-failed",
            challengeRequired: true,
            outcome: "failure"
        )

        static let cancelled = (
            transactionId: "test-tx-456",
            acsTransactionId: "test-acs-789",
            acsReferenceNumber: "test-ref-012",
            acsSignedContent: "signed-content-cancelled",
            challengeRequired: true,
            outcome: "cancelled"
        )

        static let timeout = (
            transactionId: "test-tx-567",
            acsTransactionId: "test-acs-890",
            acsReferenceNumber: "test-ref-123",
            acsSignedContent: "signed-content-timeout",
            challengeRequired: true,
            outcome: "timeout"
        )
    }

    // MARK: - Network Responses

    /// Typealias for network response tuple to avoid `as X?` clutter
    typealias NetworkResponseResult = (data: Data?, response: HTTPURLResponse?, error: Error?)

    enum NetworkResponses {
        private static let testURL = URL(string: "https://api.primer.io/test")!
        private static let defaultHeaders = ["Content-Type": "application/json"]

        static func success200(with data: Data? = nil) -> NetworkResponseResult {
            let json = data ?? APIResponses.validPaymentMethods.data(using: .utf8)
            let response = HTTPURLResponse(
                url: testURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: defaultHeaders
            )
            return (json, response, nil)
        }

        static let badRequest400: NetworkResponseResult = (
            data: nil,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 400,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil
        )

        static let unauthorized401: NetworkResponseResult = (
            data: nil,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 401,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil
        )

        static let notFound404: NetworkResponseResult = (
            data: nil,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 404,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil
        )

        static let serverError500: NetworkResponseResult = (
            data: nil,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 500,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil
        )

        static let timeout: NetworkResponseResult = (
            data: nil,
            response: nil,
            error: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
            )
        )

        static let noConnection: NetworkResponseResult = (
            data: nil,
            response: nil,
            error: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
            )
        )
    }
}
