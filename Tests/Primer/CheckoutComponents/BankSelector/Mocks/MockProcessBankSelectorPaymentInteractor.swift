//
//  MockProcessBankSelectorPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockProcessBankSelectorPaymentInteractor: ProcessBankSelectorPaymentInteractor {

    // MARK: - Configurable Return Values

    var banksToReturn: [Bank]?
    var paymentResultToReturn: PaymentResult?

    // MARK: - Error Configuration

    var fetchBanksError: Error?
    var executeError: Error?

    // MARK: - Call Tracking

    private(set) var fetchBanksCallCount = 0
    private(set) var executeCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastFetchBanksPaymentMethodType: String?
    private(set) var lastExecuteBankId: String?
    private(set) var lastExecutePaymentMethodType: String?

    // MARK: - Closures for Custom Behavior

    var onFetchBanks: ((String) async throws -> [Bank])?
    var onExecute: ((String, String) async throws -> PaymentResult)?

    // MARK: - ProcessBankSelectorPaymentInteractor Protocol

    func fetchBanks(paymentMethodType: String) async throws -> [Bank] {
        fetchBanksCallCount += 1
        lastFetchBanksPaymentMethodType = paymentMethodType

        if let onFetchBanks {
            return try await onFetchBanks(paymentMethodType)
        }

        if let fetchBanksError {
            throw fetchBanksError
        }

        guard let banks = banksToReturn else {
            throw TestError.unknown
        }
        return banks
    }

    func execute(bankId: String, paymentMethodType: String) async throws -> PaymentResult {
        executeCallCount += 1
        lastExecuteBankId = bankId
        lastExecutePaymentMethodType = paymentMethodType

        if let onExecute {
            return try await onExecute(bankId, paymentMethodType)
        }

        if let executeError {
            throw executeError
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }
}
