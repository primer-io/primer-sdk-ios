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
public class CheckoutViewModel: PrimerCheckoutScope, LogReporter {
    
    // MARK: - Published State
    
    @Published private var _state: CheckoutState = .notInitialized
    
    // MARK: - PrimerCheckoutScope Implementation
    
    public var state: AnyPublisher<CheckoutState, Never> {
        $_state.eraseToAnyPublisher()
    }
    
    // MARK: - Dependencies
    
    private let container: DIContainer
    
    // MARK: - Initialization
    
    public init(container: DIContainer) async throws {
        self.container = container
        logger.debug(message: "🚀 [CheckoutViewModel] Initializing checkout")
        await initialize()
    }
    
    // MARK: - Public Methods
    
    public func configure(clientToken: String, settings: PrimerSettings) async {
        logger.debug(message: "⚙️ [CheckoutViewModel] Configuring with client token")
        
        _state = .initializing
        
        do {
            // TODO: Implement actual client token processing
            // For now, simulate configuration
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            _state = .ready
            logger.info(message: "✅ [CheckoutViewModel] Checkout configured successfully")
            
        } catch {
            logger.error(message: "❌ [CheckoutViewModel] Failed to configure: \(error)")
            _state = .error(error)
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