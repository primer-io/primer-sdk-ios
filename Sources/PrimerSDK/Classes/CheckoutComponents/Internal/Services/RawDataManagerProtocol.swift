//
//  RawDataManagerProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Protocol abstracting the RawDataManager interface for testability
/// This allows HeadlessRepositoryImpl to use a mock in tests
@available(iOS 15.0, *)
protocol RawDataManagerProtocol: AnyObject {
    /// The delegate that receives validation and metadata callbacks
    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? { get set }

    /// The raw payment data (e.g., card data)
    var rawData: PrimerRawData? { get set }

    /// Whether the current raw data is valid
    var isDataValid: Bool { get }

    /// The required input element types for this payment method
    var requiredInputElementTypes: [PrimerInputElementType] { get }

    /// Configures the raw data manager with additional initialization data
    /// - Parameter completion: Callback with optional initialization data and error
    func configure(completion: @escaping (PrimerInitializationData?, Error?) -> Void)

    /// Submits the payment with the current raw data
    func submit()
}

/// Factory protocol for creating RawDataManager instances
/// This allows injection of mock factories in tests
@available(iOS 15.0, *)
protocol RawDataManagerFactoryProtocol {
    /// Creates a new RawDataManager instance
    /// - Parameters:
    ///   - paymentMethodType: The type of payment method (e.g., "PAYMENT_CARD")
    ///   - delegate: The delegate to receive callbacks
    /// - Returns: A configured RawDataManager
    /// - Throws: Error if the payment method type is unsupported
    func createRawDataManager(
        paymentMethodType: String,
        delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    ) throws -> RawDataManagerProtocol
}

/// Default factory that creates real RawDataManager instances
@available(iOS 15.0, *)
final class DefaultRawDataManagerFactory: RawDataManagerFactoryProtocol {
    func createRawDataManager(
        paymentMethodType: String,
        delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    ) throws -> RawDataManagerProtocol {
        try PrimerHeadlessUniversalCheckout.RawDataManager(
            paymentMethodType: paymentMethodType,
            delegate: delegate
        )
    }
}

// MARK: - RawDataManager Conformance

@available(iOS 15.0, *)
extension PrimerHeadlessUniversalCheckout.RawDataManager: RawDataManagerProtocol {}
