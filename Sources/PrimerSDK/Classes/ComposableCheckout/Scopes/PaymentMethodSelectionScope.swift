//
//  PaymentMethodSelectionScope.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Payment method selection scope that provides access to available payment methods.
/// This matches Android's PaymentMethodSelectionScope interface exactly.
@available(iOS 15.0, *)
public protocol PaymentMethodSelectionScope: ObservableObject {
    
    /// Reactive state stream for payment method selection
    var state: AnyPublisher<PaymentMethodSelectionState, Never> { get }
    
    /// Handle payment method selection
    func onPaymentMethodSelected(_ paymentMethod: PrimerComposablePaymentMethod)
}

// MARK: - Extension Functions (matches Android's companion object)

@available(iOS 15.0, *)
public extension PaymentMethodSelectionScope {
    
    /// Payment method selection screen component
    @ViewBuilder
    func PrimerPaymentMethodSelectionScreen() -> some View {
        PaymentMethodSelectionScreenView(scope: self)
    }
    
    /// Individual payment method item component
    @ViewBuilder
    func PrimerPaymentMethodItem(
        paymentMethod: PrimerComposablePaymentMethod,
        currency: Currency? = nil
    ) -> some View {
        PaymentMethodItemView(
            scope: self,
            paymentMethod: paymentMethod,
            currency: currency
        )
    }
}

// MARK: - State Model

/// State model for payment method selection (matches Android)
public enum PaymentMethodSelectionState {
    case loading
    case ready(paymentMethods: [PrimerComposablePaymentMethod], currency: Currency?)
    case error(Error)
}

// MARK: - Payment Method Model

/// Simple payment method model (matches Android structure)
public struct PrimerComposablePaymentMethod: Identifiable, Equatable {
    public let id: String
    public let paymentMethodType: String
    public let paymentMethodName: String?
    public let supportedIntents: [PrimerSessionIntent]
    public let paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]
    public let requiredInputDataClass: Any.Type?
    public let surcharge: Surcharge?
    
    public init(
        paymentMethodType: String,
        paymentMethodName: String? = nil,
        supportedIntents: [PrimerSessionIntent] = [],
        paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory] = [],
        requiredInputDataClass: Any.Type? = nil,
        surcharge: Surcharge? = nil
    ) {
        self.id = paymentMethodType
        self.paymentMethodType = paymentMethodType
        self.paymentMethodName = paymentMethodName
        self.supportedIntents = supportedIntents
        self.paymentMethodManagerCategories = paymentMethodManagerCategories
        self.requiredInputDataClass = requiredInputDataClass
        self.surcharge = surcharge
    }
    
    public static func == (lhs: PrimerComposablePaymentMethod, rhs: PrimerComposablePaymentMethod) -> Bool {
        lhs.paymentMethodType == rhs.paymentMethodType
    }
}

// MARK: - Supporting Models (placeholders for now)

public enum PrimerSessionIntent {
    case checkout
    case vault
}

public enum PrimerPaymentMethodManagerCategory {
    case nativeUI
    case webRedirect
}

public struct Surcharge {
    public let amount: Double
    public let currency: String
    
    public init(amount: Double, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

public struct Currency {
    public let code: String
    public let symbol: String
    
    public init(code: String, symbol: String) {
        self.code = code
        self.symbol = symbol
    }
}

// MARK: - Default Implementation (Temporary)

/// Temporary default implementation for testing
@available(iOS 15.0, *)
internal class DefaultPaymentMethodSelectionScope: PaymentMethodSelectionScope, LogReporter {
    
    @Published private var _state: PaymentMethodSelectionState = .loading
    
    public var state: AnyPublisher<PaymentMethodSelectionState, Never> {
        $_state.eraseToAnyPublisher()
    }
    
    init() {
        loadPaymentMethods()
    }
    
    public func onPaymentMethodSelected(_ paymentMethod: PrimerComposablePaymentMethod) {
        logger.debug(message: "🎯 [DefaultPaymentMethodSelectionScope] Selected: \(paymentMethod.paymentMethodType)")
        
        // TODO: Navigate to appropriate screen based on payment method type
        // For now, just log the selection
        NotificationCenter.default.post(
            name: .paymentMethodSelected,
            object: paymentMethod
        )
    }
    
    // MARK: - Private Methods
    
    private func loadPaymentMethods() {
        logger.debug(message: "📋 [DefaultPaymentMethodSelectionScope] Loading payment methods")
        
        Task {
            // Simulate loading
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let mockPaymentMethods = [
                PrimerComposablePaymentMethod(
                    paymentMethodType: "PAYMENT_CARD",
                    paymentMethodName: "Credit Card"
                ),
                PrimerComposablePaymentMethod(
                    paymentMethodType: "APPLE_PAY",
                    paymentMethodName: "Apple Pay"
                ),
                PrimerComposablePaymentMethod(
                    paymentMethodType: "PAYPAL",
                    paymentMethodName: "PayPal"
                )
            ]
            
            let currency = Currency(code: "USD", symbol: "$")
            
            await MainActor.run {
                _state = .ready(
                    paymentMethods: mockPaymentMethods,
                    currency: currency
                )
                logger.info(message: "✅ [DefaultPaymentMethodSelectionScope] Loaded \(mockPaymentMethods.count) payment methods")
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let paymentMethodSelected = Notification.Name("paymentMethodSelected")
    static let paymentCompleted = Notification.Name("paymentCompleted")
}

// MARK: - Forward Declarations for UI Components

// These will be implemented in Phase 5

@available(iOS 15.0, *)
internal struct PaymentMethodSelectionScreenView: View {
    let scope: any PaymentMethodSelectionScope
    @State private var paymentMethods: [PrimerComposablePaymentMethod] = []
    @State private var currency: Currency?
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading payment methods...")
            } else {
                Text("Payment Method Selection Screen")
                Text("\(paymentMethods.count) methods available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onReceive(scope.state) { state in
            switch state {
            case .loading:
                isLoading = true
            case .ready(let methods, let curr):
                paymentMethods = methods
                currency = curr
                isLoading = false
            case .error:
                isLoading = false
            }
        }
    }
}

@available(iOS 15.0, *)
internal struct PaymentMethodItemView: View {
    let scope: any PaymentMethodSelectionScope
    let paymentMethod: PrimerComposablePaymentMethod
    let currency: Currency?
    
    var body: some View {
        Button(action: {
            scope.onPaymentMethodSelected(paymentMethod)
        }) {
            HStack {
                Image(systemName: iconForPaymentMethod(paymentMethod.paymentMethodType))
                
                VStack(alignment: .leading) {
                    Text(paymentMethod.paymentMethodName ?? paymentMethod.paymentMethodType)
                        .font(.headline)
                    
                    if let surcharge = paymentMethod.surcharge {
                        Text("+ \(surcharge.amount) \(currency?.code ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func iconForPaymentMethod(_ type: String) -> String {
        switch type {
        case "PAYMENT_CARD":
            return "creditcard.fill"
        case "APPLE_PAY":
            return "applelogo"
        case "PAYPAL":
            return "p.circle.fill"
        default:
            return "creditcard"
        }
    }
}