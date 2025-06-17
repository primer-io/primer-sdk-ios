//
//  PaymentMethodSelectionViewModel.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// PaymentMethodSelectionViewModel implements the PaymentMethodSelectionScope protocol.
/// This provides payment method selection functionality accessible through the Android-matching API.
@available(iOS 15.0, *)
@MainActor
public class PaymentMethodSelectionViewModel: PaymentMethodSelectionScope, LogReporter {
    
    // MARK: - Published State
    
    @Published private var _state: PaymentMethodSelectionState = .loading
    
    // MARK: - PaymentMethodSelectionScope Implementation
    
    public var state: AnyPublisher<PaymentMethodSelectionState, Never> {
        $_state.eraseToAnyPublisher()
    }
    
    // MARK: - Dependencies
    
    private let container: DIContainer
    
    // MARK: - Initialization
    
    public init(container: DIContainer) async throws {
        self.container = container
        logger.debug(message: "📋 [PaymentMethodSelectionViewModel] Initializing payment method selection")
        await loadPaymentMethods()
    }
    
    // MARK: - Public Methods
    
    public func onPaymentMethodSelected(_ paymentMethod: PrimerComposablePaymentMethod) {
        logger.debug(message: "🎯 [PaymentMethodSelectionViewModel] Selected: \(paymentMethod.paymentMethodType)")
        
        Task {
            do {
                // Handle navigation based on payment method type
                await handlePaymentMethodSelection(paymentMethod)
                
            } catch {
                logger.error(message: "❌ [PaymentMethodSelectionViewModel] Selection failed: \(error)")
            }
        }
    }
    
    public func refreshPaymentMethods() async {
        logger.debug(message: "🔄 [PaymentMethodSelectionViewModel] Refreshing payment methods")
        _state = .loading
        await loadPaymentMethods()
    }
    
    // MARK: - Private Methods
    
    private func loadPaymentMethods() async {
        logger.debug(message: "📥 [PaymentMethodSelectionViewModel] Loading payment methods")
        
        do {
            // TODO: Implement actual payment method loading through services
            // For now, create mock payment methods
            let paymentMethods = await createMockPaymentMethods()
            let currency = Currency(code: "USD", symbol: "$")
            
            _state = .ready(paymentMethods: paymentMethods, currency: currency)
            logger.info(message: "✅ [PaymentMethodSelectionViewModel] Loaded \(paymentMethods.count) payment methods")
            
        } catch {
            logger.error(message: "❌ [PaymentMethodSelectionViewModel] Failed to load payment methods: \(error)")
            _state = .error(error)
        }
    }
    
    private func createMockPaymentMethods() async -> [PrimerComposablePaymentMethod] {
        logger.debug(message: "🎭 [PaymentMethodSelectionViewModel] Creating mock payment methods")
        
        // Simulate loading delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return [
            PrimerComposablePaymentMethod(
                paymentMethodType: "PAYMENT_CARD",
                paymentMethodName: "Credit Card",
                description: "Pay with your credit or debit card",
                iconUrl: nil,
                surcharge: nil
            ),
            PrimerComposablePaymentMethod(
                paymentMethodType: "APPLE_PAY",
                paymentMethodName: "Apple Pay",
                description: "Pay securely with Touch ID or Face ID",
                iconUrl: nil,
                surcharge: nil
            ),
            PrimerComposablePaymentMethod(
                paymentMethodType: "PAYPAL",
                paymentMethodName: "PayPal",
                description: "Pay with your PayPal account",
                iconUrl: nil,
                surcharge: PrimerComposablePaymentMethodSurcharge(
                    amount: 250,
                    currency: "USD"
                )
            ),
            PrimerComposablePaymentMethod(
                paymentMethodType: "GOOGLE_PAY",
                paymentMethodName: "Google Pay",
                description: "Pay with Google Pay",
                iconUrl: nil,
                surcharge: nil
            )
        ]
    }
    
    private func handlePaymentMethodSelection(_ paymentMethod: PrimerComposablePaymentMethod) async {
        logger.debug(message: "🚀 [PaymentMethodSelectionViewModel] Handling selection: \(paymentMethod.paymentMethodType)")
        
        switch paymentMethod.paymentMethodType {
        case "PAYMENT_CARD":
            logger.debug(message: "💳 [PaymentMethodSelectionViewModel] Navigating to card form")
            NotificationCenter.default.post(
                name: .navigateToCardForm,
                object: paymentMethod
            )
            
        case "APPLE_PAY":
            logger.debug(message: "🍎 [PaymentMethodSelectionViewModel] Processing Apple Pay")
            // TODO: Implement Apple Pay flow
            NotificationCenter.default.post(
                name: .processApplePay,
                object: paymentMethod
            )
            
        case "PAYPAL":
            logger.debug(message: "💙 [PaymentMethodSelectionViewModel] Processing PayPal")
            // TODO: Implement PayPal flow
            NotificationCenter.default.post(
                name: .processPayPal,
                object: paymentMethod
            )
            
        default:
            logger.debug(message: "❓ [PaymentMethodSelectionViewModel] Unknown payment method: \(paymentMethod.paymentMethodType)")
            NotificationCenter.default.post(
                name: .paymentMethodSelected,
                object: paymentMethod
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToCardForm = Notification.Name("navigateToCardForm")
    static let processApplePay = Notification.Name("processApplePay")
    static let processPayPal = Notification.Name("processPayPal")
}