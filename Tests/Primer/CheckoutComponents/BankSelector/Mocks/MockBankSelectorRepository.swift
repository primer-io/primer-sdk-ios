//
//  MockBankSelectorRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockBankSelectorRepository: BankSelectorRepository {

    // MARK: - Configurable Return Values

    var banksToReturn: [AdyenBank]?
    var paymentResultToReturn: PaymentResult?

    // MARK: - Error Configuration

    var fetchBanksError: Error?
    var tokenizeError: Error?

    // MARK: - Call Tracking

    private(set) var fetchBanksCallCount = 0
    private(set) var tokenizeCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastFetchBanksConfigId: String?
    private(set) var lastFetchBanksPaymentMethod: String?
    private(set) var lastTokenizeConfigId: String?
    private(set) var lastTokenizePaymentMethodType: String?
    private(set) var lastTokenizeBankId: String?

    // MARK: - BankSelectorRepository Protocol

    func fetchBanks(
        paymentMethodConfigId: String,
        paymentMethod: String
    ) async throws -> [AdyenBank] {
        fetchBanksCallCount += 1
        lastFetchBanksConfigId = paymentMethodConfigId
        lastFetchBanksPaymentMethod = paymentMethod

        if let fetchBanksError {
            throw fetchBanksError
        }

        guard let banks = banksToReturn else {
            throw TestError.unknown
        }
        return banks
    }

    func tokenize(
        paymentMethodConfigId: String,
        paymentMethodType: String,
        bankId: String
    ) async throws -> PaymentResult {
        tokenizeCallCount += 1
        lastTokenizeConfigId = paymentMethodConfigId
        lastTokenizePaymentMethodType = paymentMethodType
        lastTokenizeBankId = bankId

        if let tokenizeError {
            throw tokenizeError
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }
}
