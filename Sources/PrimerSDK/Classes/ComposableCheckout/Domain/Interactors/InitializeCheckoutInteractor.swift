//
//  InitializeCheckoutInteractor.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Interactor (Use Case) for initializing the checkout process
@available(iOS 15.0, *)
internal protocol InitializeCheckoutInteractor: LogReporter {
    /// Executes the initialization of checkout with the provided client token
    /// - Parameter clientToken: The client token for SDK initialization
    /// - Returns: CheckoutConfiguration containing all necessary checkout data
    /// - Throws: Error if initialization fails
    func execute(clientToken: String) async throws -> CheckoutConfiguration
}

/// Implementation of InitializeCheckoutInteractor
@available(iOS 15.0, *)
internal class InitializeCheckoutInteractorImpl: InitializeCheckoutInteractor, LogReporter {
    
    // MARK: - Dependencies
    
    private let configurationRepository: ConfigurationRepository
    private let paymentMethodRepository: PaymentMethodRepository
    
    // MARK: - Initialization
    
    init(
        configurationRepository: ConfigurationRepository,
        paymentMethodRepository: PaymentMethodRepository
    ) {
        self.configurationRepository = configurationRepository
        self.paymentMethodRepository = paymentMethodRepository
        logger.debug(message: "🏗️ [InitializeCheckoutInteractor] Initialized")
    }
    
    // MARK: - InitializeCheckoutInteractor
    
    func execute(clientToken: String) async throws -> CheckoutConfiguration {
        logger.debug(message: "🚀 [InitializeCheckoutInteractor] Starting checkout initialization")
        
        do {
            // Initialize configuration
            logger.debug(message: "🔧 [InitializeCheckoutInteractor] Initializing configuration")
            let config = try await configurationRepository.initialize(clientToken: clientToken)
            
            // Fetch available payment methods
            logger.debug(message: "💳 [InitializeCheckoutInteractor] Fetching payment methods")
            let paymentMethods = try await paymentMethodRepository.getAvailablePaymentMethods()
            
            // Fetch currency information
            logger.debug(message: "💰 [InitializeCheckoutInteractor] Fetching currency info")
            let currency = try await paymentMethodRepository.getCurrency()
            
            let checkoutConfig = CheckoutConfiguration(
                config: config,
                paymentMethods: paymentMethods,
                currency: currency
            )
            
            logger.info(message: "✅ [InitializeCheckoutInteractor] Checkout initialization completed successfully")
            logger.debug(message: "📊 [InitializeCheckoutInteractor] Found \(paymentMethods.count) payment methods")
            
            return checkoutConfig
            
        } catch {
            logger.error(message: "❌ [InitializeCheckoutInteractor] Initialization failed: \(error.localizedDescription)")
            throw error
        }
    }
}