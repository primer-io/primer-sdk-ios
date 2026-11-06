//
//  MockPKPayment.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit

@available(iOS 15.0, *)
final class SharedMockPKPayment: PKPayment {

    private let mockToken = SharedMockPKPaymentToken()

    override var token: PKPaymentToken { mockToken }
}

@available(iOS 15.0, *)
final class SharedMockPKPaymentToken: PKPaymentToken {

    private let mockPaymentMethod = SharedMockPKPaymentMethod()

    override var paymentMethod: PKPaymentMethod { mockPaymentMethod }
    override var transactionIdentifier: String { "mock_transaction_id" }
    override var paymentData: Data { Data() }
}

@available(iOS 15.0, *)
final class SharedMockPKPaymentMethod: PKPaymentMethod {

    override var displayName: String? { "Mock Card" }
    override var network: PKPaymentNetwork? { .visa }
    override var type: PKPaymentMethodType { .debit }
}
