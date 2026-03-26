//
//  QRCodeTestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum QRCodeTestData {

    // MARK: - Constants

    enum Constants {
        static let paymentMethodType = "XFERS_PAYNOW"
        static let paymentId = "pay_qr_123"
        static let resumeToken = "resume_token_abc"
        static let statusUrl = URL(string: "https://api.primer.io/status/qr-123")!
        static let mockToken = "mock_client_token"
    }

    // MARK: - Payment Data

    static var defaultPaymentData: QRCodePaymentData {
        QRCodePaymentData(
            qrCodeImageData: Data(),
            statusUrl: Constants.statusUrl,
            paymentId: Constants.paymentId
        )
    }

    // MARK: - Payment Results

    static var successPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .success,
            paymentMethodType: Constants.paymentMethodType
        )
    }

    static var failedPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .failed,
            paymentMethodType: Constants.paymentMethodType
        )
    }
}
