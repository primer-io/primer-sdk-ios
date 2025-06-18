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
    
    private let container: any ContainerProtocol
    private let getPaymentMethodsInteractor: GetPaymentMethodsInteractor
    
    // MARK: - Initialization
    
    public init(container: any ContainerProtocol) async throws {
        self.container = container
        self.getPaymentMethodsInteractor = try await container.resolve(GetPaymentMethodsInteractor.self, name: nil)
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
            // Use Clean Architecture Interactor to load payment methods
            let paymentMethods = try await getPaymentMethodsInteractor.execute()
            let currency = try await getPaymentMethodsInteractor.getCurrency()
            
            _state = .ready(paymentMethods: paymentMethods, currency: currency)
            logger.info(message: "✅ [PaymentMethodSelectionViewModel] Loaded \(paymentMethods.count) payment methods")
            
        } catch {
            logger.error(message: "❌ [PaymentMethodSelectionViewModel] Failed to load payment methods: \(error)")
            _state = .error(error.localizedDescription)
        }
    }
    
    private func createMockPaymentMethods() async -> [PrimerComposablePaymentMethod] {
        logger.debug(message: "📥 [PaymentMethodSelectionViewModel] Loading payment methods from service")
        
        // TODO: Integrate with actual payment method loading service
        // For now, create structured mock data that represents real payment methods
        
        // Simulate network loading delay
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        let availablePaymentMethods = [
            createPaymentMethod(
                type: "PAYMENT_CARD",
                name: "Credit Card",
                description: "Pay with your credit or debit card",
                iconUrl: "https://assets.primer.io/icons/payment_card.svg"
            ),
            createPaymentMethod(
                type: "APPLE_PAY",
                name: "Apple Pay",
                description: "Pay securely with Touch ID or Face ID",
                iconUrl: "https://assets.primer.io/icons/apple_pay.svg"
            ),
            createPaymentMethod(
                type: "PAYPAL",
                name: "PayPal",
                description: "Pay with your PayPal account",
                iconUrl: "https://assets.primer.io/icons/paypal.svg",
                surcharge: PrimerComposablePaymentMethodSurcharge(amount: 250, currency: "USD")
            ),
            createPaymentMethod(
                type: "GOOGLE_PAY",
                name: "Google Pay",
                description: "Pay with Google Pay",
                iconUrl: "https://assets.primer.io/icons/google_pay.svg"
            )
        ]
        
        // Filter available payment methods based on device capabilities
        let filteredMethods = await filterPaymentMethodsForDevice(availablePaymentMethods)
        
        logger.info(message: "✅ [PaymentMethodSelectionViewModel] Loaded \(filteredMethods.count) payment methods")
        return filteredMethods
    }
    
    /// Create a payment method with proper structure
    private func createPaymentMethod(
        type: String,
        name: String,
        description: String,
        iconUrl: String,
        surcharge: PrimerComposablePaymentMethodSurcharge? = nil
    ) -> PrimerComposablePaymentMethod {
        return PrimerComposablePaymentMethod(
            paymentMethodType: type,
            paymentMethodName: name,
            description: description,
            iconUrl: iconUrl,
            surcharge: surcharge
        )
    }
    
    /// Filter payment methods based on device capabilities
    private func filterPaymentMethodsForDevice(_ methods: [PrimerComposablePaymentMethod]) async -> [PrimerComposablePaymentMethod] {
        logger.debug(message: "🔍 [PaymentMethodSelectionViewModel] Filtering payment methods for device")
        
        return methods.filter { method in
            switch method.paymentMethodType {
            case "APPLE_PAY":
                // TODO: Check if Apple Pay is available on device
                return true // For now, always show Apple Pay
            case "GOOGLE_PAY":
                // Google Pay is not available on iOS
                return false
            default:
                return true
            }
        }
    }
    
    private func handlePaymentMethodSelection(_ paymentMethod: PrimerComposablePaymentMethod) async {
        logger.debug(message: "🚀 [PaymentMethodSelectionViewModel] Handling selection: \(paymentMethod.paymentMethodType)")
        
        do {
            switch paymentMethod.paymentMethodType {
            case "PAYMENT_CARD":
                logger.debug(message: "💳 [PaymentMethodSelectionViewModel] Navigating to card form")
                await navigateToCardForm(paymentMethod)
                
            case "APPLE_PAY":
                logger.debug(message: "🍎 [PaymentMethodSelectionViewModel] Processing Apple Pay")
                await processApplePay(paymentMethod)
                
            case "PAYPAL":
                logger.debug(message: "💙 [PaymentMethodSelectionViewModel] Processing PayPal")
                await processPayPal(paymentMethod)
                
            default:
                logger.debug(message: "❓ [PaymentMethodSelectionViewModel] Unknown payment method: \(paymentMethod.paymentMethodType)")
                NotificationCenter.default.post(
                    name: .paymentMethodSelected,
                    object: paymentMethod
                )
            }
        } catch {
            logger.error(message: "❌ [PaymentMethodSelectionViewModel] Failed to handle selection: \(error)")
        }
    }
    
    // MARK: - Navigation Methods
    
    private func navigateToCardForm(_ paymentMethod: PrimerComposablePaymentMethod) async {
        logger.debug(message: "🧭 [PaymentMethodSelectionViewModel] Preparing card form navigation")
        
        // Pre-initialize card form scope for faster navigation
        do {
            let _ = try await container.resolve(CardFormViewModel.self)
            
            // Notify navigation system
            NotificationCenter.default.post(
                name: .navigateToCardForm,
                object: paymentMethod
            )
            
        } catch {
            logger.error(message: "❌ [PaymentMethodSelectionViewModel] Failed to prepare card form: \(error)")
        }
    }
    
    private func processApplePay(_ paymentMethod: PrimerComposablePaymentMethod) async {
        logger.debug(message: "🍎 [PaymentMethodSelectionViewModel] Starting Apple Pay flow")
        
        // TODO: Integrate with Apple Pay service
        // For now, just notify the system
        NotificationCenter.default.post(
            name: .processApplePay,
            object: paymentMethod
        )
    }
    
    private func processPayPal(_ paymentMethod: PrimerComposablePaymentMethod) async {
        logger.debug(message: "💙 [PaymentMethodSelectionViewModel] Starting PayPal flow")
        
        // TODO: Integrate with PayPal service
        // For now, just notify the system
        NotificationCenter.default.post(
            name: .processPayPal,
            object: paymentMethod
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToCardForm = Notification.Name("navigateToCardForm")
    static let processApplePay = Notification.Name("processApplePay")
    static let processPayPal = Notification.Name("processPayPal")
}