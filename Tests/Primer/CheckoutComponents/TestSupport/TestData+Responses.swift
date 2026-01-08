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

    enum NetworkResponses {
        private static let testURL = URL(string: "https://api.primer.io/test")!
        private static let defaultHeaders = ["Content-Type": "application/json"]

        static func success200(with data: Data? = nil) -> (Data?, HTTPURLResponse?, Error?) {
            let json = data ?? APIResponses.validPaymentMethods.data(using: .utf8)
            let response = HTTPURLResponse(
                url: testURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: defaultHeaders
            )
            return (json, response, nil)
        }

        static let badRequest400 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 400,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        static let unauthorized401 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 401,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        static let notFound404 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 404,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        static let serverError500 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 500,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        static let timeout = (
            data: nil as Data?,
            response: nil as HTTPURLResponse?,
            error: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
            ) as Error
        )

        static let noConnection = (
            data: nil as Data?,
            response: nil as HTTPURLResponse?,
            error: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
            ) as Error
        )
    }

    // MARK: - Errors

    enum Errors {
        static let networkError = NSError(
            domain: "TestError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Network connection failed"]
        )

        static let networkTimeout = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
        )

        static let validationError = NSError(
            domain: "ValidationError",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: "Validation failed"]
        )

        static let invalidCardNumber = NSError(
            domain: "PrimerValidationError",
            code: 1001,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid card number",
                "field": "cardNumber"
            ]
        )

        static let expiredCard = NSError(
            domain: "PrimerValidationError",
            code: 1002,
            userInfo: [
                NSLocalizedDescriptionKey: "Card has expired",
                "field": "expiryDate"
            ]
        )

        static let invalidCVV = NSError(
            domain: "PrimerValidationError",
            code: 1003,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid CVV",
                "field": "cvv"
            ]
        )

        static let paymentDeclined = NSError(
            domain: "PaymentError",
            code: 402,
            userInfo: [NSLocalizedDescriptionKey: "Payment was declined"]
        )

        static let insufficientFunds = NSError(
            domain: "PaymentError",
            code: 4001,
            userInfo: [NSLocalizedDescriptionKey: "Payment declined: Insufficient funds"]
        )

        static let fraudCheck = NSError(
            domain: "PaymentError",
            code: 4002,
            userInfo: [NSLocalizedDescriptionKey: "Payment declined: Fraud check failed"]
        )

        static let serverError = NSError(
            domain: "ServerError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Internal server error"]
        )

        static let invalidMerchantConfig = NSError(
            domain: "ConfigurationError",
            code: 5001,
            userInfo: [NSLocalizedDescriptionKey: "Invalid merchant configuration"]
        )

        static let missingAPIKey = NSError(
            domain: "ConfigurationError",
            code: 5002,
            userInfo: [NSLocalizedDescriptionKey: "Missing API key"]
        )

        static let threeDSInitializationFailed = NSError(
            domain: "Primer3DSError",
            code: 6001,
            userInfo: [NSLocalizedDescriptionKey: "3DS initialization failed"]
        )

        static let threeDSChallengeTimeout = NSError(
            domain: "Primer3DSError",
            code: 6002,
            userInfo: [NSLocalizedDescriptionKey: "3DS challenge timed out"]
        )

        static let threeDSChallengeCancelled = NSError(
            domain: "Primer3DSError",
            code: 6003,
            userInfo: [NSLocalizedDescriptionKey: "3DS challenge was cancelled"]
        )

        static let authenticationRequired = NSError(
            domain: "AuthError",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Authentication required"]
        )

        static let unknown = NSError(
            domain: "UnknownError",
            code: 9999,
            userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred"]
        )
    }
}
