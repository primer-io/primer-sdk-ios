//
//  CheckoutViewModel.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// CheckoutViewModel implements the PrimerCheckoutScope protocol and manages the overall checkout flow.
/// This provides the main checkout functionality accessible through the Android-matching API.
@available(iOS 15.0, *)
@MainActor
public class CheckoutViewModel: PrimerCheckoutScope, ObservableObject, LogReporter {

    // MARK: - Published State

    @Published private var _state: CheckoutState = .notInitialized

    // MARK: - PrimerCheckoutScope Implementation

    public func state() -> AsyncStream<CheckoutState> {
        PublishedAsyncStream.create(from: self, keyPath: \._state)
    }

    public func paymentMethods() -> AsyncStream<[any PaymentMethodProtocol]> {
        return AsyncStream { continuation in
            // TODO: Implement payment methods streaming
            // For now, return empty array
            continuation.yield([])
            continuation.finish()
        }
    }

    public func selectedPaymentMethod() -> AsyncStream<(any PaymentMethodProtocol)?> {
        return AsyncStream { continuation in
            // TODO: Implement selected payment method streaming
            // For now, return nil
            continuation.yield(nil)
            continuation.finish()
        }
    }

    public func selectPaymentMethod(_ method: (any PaymentMethodProtocol)?) async {
        // TODO: Implement payment method selection
        logger.debug(message: "🎯 [CheckoutViewModel] Payment method selected: \(method?.name ?? "nil")")
    }

    // MARK: - Dependencies

    private let container: any ContainerProtocol
    private let initializeCheckoutInteractor: InitializeCheckoutInteractor
    private var clientToken: String?
    private var settings: PrimerSettings?

    // MARK: - Initialization

    public init(container: any ContainerProtocol) async throws {
        self.container = container
        self.initializeCheckoutInteractor = try await container.resolve(InitializeCheckoutInteractor.self, name: nil)
        logger.debug(message: "🚀 [CheckoutViewModel] Initializing checkout")
        await initialize()
    }

    // MARK: - Public Methods

    public func configure(clientToken: String, settings: PrimerSettings) async {
        logger.debug(message: "⚙️ [CheckoutViewModel] Configuring with client token: \(clientToken.prefix(8))...")

        _state = .initializing

        do {
            // Validate client token format
            guard !clientToken.isEmpty else {
                throw CheckoutError.invalidClientToken
            }

            // Store configuration
            self.clientToken = clientToken
            self.settings = settings

            // Use Clean Architecture Interactor to initialize checkout
            let checkoutConfiguration = try await initializeCheckoutInteractor.execute(clientToken: clientToken)

            logger.debug(message: "✅ [CheckoutViewModel] Checkout configuration received with \(checkoutConfiguration.paymentMethods.count) payment methods")

            _state = .ready
            logger.info(message: "✅ [CheckoutViewModel] Checkout configured successfully")

        } catch {
            logger.error(message: "❌ [CheckoutViewModel] Failed to configure: \(error)")
            _state = .error(error.localizedDescription)
        }
    }

    public func getCardFormScope() async throws -> any CardFormScope {
        guard case .ready = _state else {
            throw CheckoutError.notReady
        }

        logger.debug(message: "💳 [CheckoutViewModel] Creating card form scope")
        return try await container.resolve(CardFormViewModel.self)
    }

    public func getPaymentMethodSelectionScope() async throws -> any PaymentMethodSelectionScope {
        guard case .ready = _state else {
            throw CheckoutError.notReady
        }

        logger.debug(message: "📋 [CheckoutViewModel] Creating payment method selection scope")
        return try await container.resolve(PaymentMethodSelectionViewModel.self)
    }

    // MARK: - Private Methods

    private func initialize() async {
        logger.debug(message: "🔧 [CheckoutViewModel] Performing initial setup")

        // Initial setup can be done here
        // For now, we just log that we're ready for configuration
        logger.info(message: "✅ [CheckoutViewModel] Ready for configuration")
    }

    /// Get current configuration
    public func getCurrentConfiguration() -> (clientToken: String?, settings: PrimerSettings?) {
        return (clientToken, settings)
    }
}

// MARK: - Checkout Error

public enum CheckoutError: Error, LocalizedError {
    case notReady
    case configurationFailed(String)
    case invalidClientToken

    public var errorDescription: String? {
        switch self {
        case .notReady:
            return "Checkout is not ready. Please call configure() first."
        case .configurationFailed(let message):
            return "Configuration failed: \(message)"
        case .invalidClientToken:
            return "Invalid client token provided."
        }
    }
}
