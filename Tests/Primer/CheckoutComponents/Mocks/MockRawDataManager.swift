//
//  MockRawDataManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockRawDataManager: RawDataManagerProtocol {

    // MARK: - Protocol Properties

    weak var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    var rawData: PrimerRawData? {
        didSet {
            rawDataSetCount += 1
            rawDataHistory.append(rawData)
            onRawDataSet?(rawData)

            if autoTriggerValidation {
                triggerValidationCallback()
            }
        }
    }

    var onRawDataSet: ((PrimerRawData?) -> Void)?
    var isDataValid: Bool = true
    var requiredInputElementTypes: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]
    var autoTriggerValidation: Bool = false
    var validationDelay: TimeInterval = 0.05

    // MARK: - Call Tracking

    private(set) var configureCallCount = 0
    private(set) var submitCallCount = 0
    private(set) var rawDataSetCount = 0
    private(set) var rawDataHistory: [PrimerRawData?] = []

    // MARK: - Configuration

    var configureError: Error?
    var initializationData: PrimerInitializationData?
    var validationErrors: [Error]?
    var onSubmit: (() -> Void)?
    var simulateSuccessfulPayment = false
    var paymentError: Error?

    // MARK: - Protocol Implementation

    func configure(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {
        configureCallCount += 1

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            completion(self.initializationData, self.configureError)
        }
    }

    func submit() {
        submitCallCount += 1
        onSubmit?()
    }

    // MARK: - Test Helpers

    func triggerValidationCallback() {
        DispatchQueue.main.asyncAfter(deadline: .now() + validationDelay) { [weak self] in
            guard let self, let delegate else { return }

            do {
                let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "PAYMENT_CARD")
                delegate.primerRawDataManager?(
                    rawDataManager,
                    dataIsValid: self.isDataValid,
                    errors: self.validationErrors
                )
            } catch {
                // Expected in unit tests without full SDK configuration
            }
        }
    }

    func triggerValidationCallback(isValid: Bool, errors: [Error]?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + validationDelay) { [weak self] in
            guard let self, let delegate else { return }

            do {
                let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "PAYMENT_CARD")
                delegate.primerRawDataManager?(
                    rawDataManager,
                    dataIsValid: isValid,
                    errors: errors
                )
            } catch {
                // Expected in unit tests without full SDK configuration
            }
        }
    }

    func reset() {
        delegate = nil
        rawData = nil
        isDataValid = true
        configureCallCount = 0
        submitCallCount = 0
        rawDataSetCount = 0
        rawDataHistory = []
        configureError = nil
        initializationData = nil
        validationErrors = nil
        onSubmit = nil
        simulateSuccessfulPayment = false
        paymentError = nil
        autoTriggerValidation = false
        validationDelay = 0.05
    }
}

// MARK: - Mock Factory

@available(iOS 15.0, *)
final class MockRawDataManagerFactory: RawDataManagerFactoryProtocol {

    // MARK: - Call Tracking

    private(set) var createCallCount = 0
    private(set) var createCalls: [(paymentMethodType: String, delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?)] = []

    // MARK: - Configuration

    var mockRawDataManager: MockRawDataManager?
    var createError: Error?
    var createMockHandler: ((String, PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?) -> MockRawDataManager)?

    // MARK: - Protocol Implementation

    func createRawDataManager(
        paymentMethodType: String,
        delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    ) throws -> RawDataManagerProtocol {
        createCallCount += 1
        createCalls.append((paymentMethodType, delegate))

        if let error = createError {
            throw error
        }

        if let handler = createMockHandler {
            let mock = handler(paymentMethodType, delegate)
            mock.delegate = delegate
            return mock
        }

        if let mock = mockRawDataManager {
            mock.delegate = delegate
            return mock
        }

        let mock = MockRawDataManager()
        mock.delegate = delegate
        return mock
    }

    // MARK: - Test Helpers

    func reset() {
        createCallCount = 0
        createCalls = []
        mockRawDataManager = nil
        createError = nil
        createMockHandler = nil
    }

    var lastCreateCall: (paymentMethodType: String, delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?)? {
        createCalls.last
    }
}
