//
//  MockRawDataManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of RawDataManagerProtocol for testing HeadlessRepositoryImpl
@available(iOS 15.0, *)
final class MockRawDataManager: RawDataManagerProtocol {

    // MARK: - Protocol Properties

    weak var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    var rawData: PrimerRawData? {
        didSet {
            rawDataSetCount += 1
            rawDataHistory.append(rawData)
            onRawDataSet?(rawData)

            // Auto-trigger validation callback if enabled
            if autoTriggerValidation {
                triggerValidationCallback()
            }
        }
    }

    /// Called when rawData is set - use this to trigger validation callbacks in tests
    var onRawDataSet: ((PrimerRawData?) -> Void)?
    var isDataValid: Bool = true
    var requiredInputElementTypes: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]

    /// When true, automatically triggers delegate validation callback when rawData is set
    var autoTriggerValidation: Bool = false

    /// Delay before triggering validation callback (simulates async behavior)
    var validationDelay: TimeInterval = 0.05

    // MARK: - Call Tracking

    private(set) var configureCallCount = 0
    private(set) var submitCallCount = 0
    private(set) var rawDataSetCount = 0
    private(set) var rawDataHistory: [PrimerRawData?] = []

    // MARK: - Configuration

    /// Error to throw from configure()
    var configureError: Error?

    /// Initialization data to return from configure()
    var initializationData: PrimerInitializationData?

    /// Validation errors for reference in tests (not automatically used in callbacks)
    var validationErrors: [Error]?

    /// Closure called when submit() is invoked
    var onSubmit: (() -> Void)?

    /// Simulates a successful payment completion
    var simulateSuccessfulPayment = false

    /// Simulates a failed payment with this error
    var paymentError: Error?

    // MARK: - Protocol Implementation

    func configure(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {
        configureCallCount += 1

        // Simulate async callback like real RawDataManager
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

    /// Manually triggers the validation callback on the delegate
    /// This simulates what the real RawDataManager does after validating rawData
    /// Uses a real RawDataManager instance to satisfy the delegate method signature
    func triggerValidationCallback() {
        DispatchQueue.main.asyncAfter(deadline: .now() + validationDelay) { [weak self] in
            guard let self, let delegate = self.delegate else { return }

            // Create a real RawDataManager for the callback (delegate only uses isValid/errors params)
            do {
                let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "PAYMENT_CARD")
                delegate.primerRawDataManager?(
                    rawDataManager,
                    dataIsValid: self.isDataValid,
                    errors: self.validationErrors
                )
            } catch {
                // If we can't create a RawDataManager, the test setup is incomplete
                // This is expected in unit tests without full SDK configuration
            }
        }
    }

    /// Triggers validation callback with custom values
    func triggerValidationCallback(isValid: Bool, errors: [Error]?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + validationDelay) { [weak self] in
            guard let self, let delegate = self.delegate else { return }

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

/// Mock factory for creating MockRawDataManager instances in tests
@available(iOS 15.0, *)
final class MockRawDataManagerFactory: RawDataManagerFactoryProtocol {

    // MARK: - Call Tracking

    private(set) var createCallCount = 0
    private(set) var createCalls: [(paymentMethodType: String, delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?)] = []

    // MARK: - Configuration

    /// The mock raw data manager to return
    var mockRawDataManager: MockRawDataManager?

    /// Error to throw when creating
    var createError: Error?

    /// Factory closure for custom mock creation
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

        // Create a default mock
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
