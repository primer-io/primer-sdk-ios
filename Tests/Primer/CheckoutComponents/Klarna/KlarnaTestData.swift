//
//  KlarnaTestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum KlarnaTestData {

    // MARK: - Constants

    enum Constants {
        static let mockToken = "mock_token"
        static let clientToken = "mock_klarna_client_token"
        static let sessionId = "mock_klarna_session_id"
        static let hppSessionId = "mock_hpp_session_id"
        static let authToken = "mock_auth_token_123"
        static let paymentId = "mock_payment_id_456"
        static let categoryPayNow = "pay_now"
        static let categoryPayLater = "pay_later"
        static let categorySliceIt = "slice_it"
    }

    // MARK: - Categories

    static var payNowCategory: KlarnaPaymentCategory {
        KlarnaPaymentCategory(
            response: Response.Body.Klarna.SessionCategory(
                identifier: Constants.categoryPayNow,
                name: "Pay now",
                descriptiveAssetUrl: "https://example.com/pay_now_descriptive.png",
                standardAssetUrl: "https://example.com/pay_now_standard.png"
            )
        )
    }

    static var payLaterCategory: KlarnaPaymentCategory {
        KlarnaPaymentCategory(
            response: Response.Body.Klarna.SessionCategory(
                identifier: Constants.categoryPayLater,
                name: "Pay in 30 days",
                descriptiveAssetUrl: "https://example.com/pay_later_descriptive.png",
                standardAssetUrl: "https://example.com/pay_later_standard.png"
            )
        )
    }

    static var sliceItCategory: KlarnaPaymentCategory {
        KlarnaPaymentCategory(
            response: Response.Body.Klarna.SessionCategory(
                identifier: Constants.categorySliceIt,
                name: "Slice it",
                descriptiveAssetUrl: "https://example.com/slice_it_descriptive.png",
                standardAssetUrl: "https://example.com/slice_it_standard.png"
            )
        )
    }

    static var allCategories: [KlarnaPaymentCategory] {
        [payNowCategory, payLaterCategory, sliceItCategory]
    }

    // MARK: - Session Results

    static var defaultSessionResult: KlarnaSessionResult {
        KlarnaSessionResult(
            clientToken: Constants.clientToken,
            sessionId: Constants.sessionId,
            categories: allCategories,
            hppSessionId: Constants.hppSessionId
        )
    }

    static var singleCategorySessionResult: KlarnaSessionResult {
        KlarnaSessionResult(
            clientToken: Constants.clientToken,
            sessionId: Constants.sessionId,
            categories: [payNowCategory],
            hppSessionId: nil
        )
    }

    // MARK: - Payment Results

    static var successPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .success,
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
        )
    }

    static var pendingPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .pending,
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
        )
    }

    static var failedPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .failed,
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
        )
    }
}
