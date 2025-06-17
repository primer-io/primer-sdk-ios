//
//  PrimerComposablePaymentMethod.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Simple payment method model that matches Android's PrimerComposablePaymentMethod exactly
public struct PrimerComposablePaymentMethod: Identifiable, Equatable {
    /// Unique identifier (derived from paymentMethodType)
    public var id: String { paymentMethodType }
    
    /// The payment method type identifier
    public let paymentMethodType: String
    
    /// Display name for the payment method (optional)
    public let paymentMethodName: String?
    
    /// List of supported session intents
    public let supportedPrimerSessionIntents: [PrimerSessionIntent]
    
    /// List of payment method manager categories
    public let paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]
    
    /// Required input data class type (optional)
    public let requiredInputDataClass: Any.Type?
    
    /// Surcharge information (optional)
    public let surcharge: Surcharge?
    
    /// Initialize a new payment method
    /// - Parameters:
    ///   - paymentMethodType: The payment method type identifier
    ///   - paymentMethodName: Display name (optional)
    ///   - supportedPrimerSessionIntents: Supported session intents
    ///   - paymentMethodManagerCategories: Manager categories
    ///   - requiredInputDataClass: Required input data type (optional)
    ///   - surcharge: Surcharge information (optional)
    public init(
        paymentMethodType: String,
        paymentMethodName: String? = nil,
        supportedPrimerSessionIntents: [PrimerSessionIntent] = [],
        paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory] = [],
        requiredInputDataClass: Any.Type? = nil,
        surcharge: Surcharge? = nil
    ) {
        self.paymentMethodType = paymentMethodType
        self.paymentMethodName = paymentMethodName
        self.supportedPrimerSessionIntents = supportedPrimerSessionIntents
        self.paymentMethodManagerCategories = paymentMethodManagerCategories
        self.requiredInputDataClass = requiredInputDataClass
        self.surcharge = surcharge
    }
    
    /// Equatable implementation based on payment method type
    public static func == (lhs: PrimerComposablePaymentMethod, rhs: PrimerComposablePaymentMethod) -> Bool {
        return lhs.paymentMethodType == rhs.paymentMethodType
    }
}

// MARK: - Supporting Enums (matching Android)

/// Session intents supported by payment methods
public enum PrimerSessionIntent: String, CaseIterable {
    case checkout = "CHECKOUT"
    case vault = "VAULT"
}

/// Payment method manager categories
public enum PrimerPaymentMethodManagerCategory: String, CaseIterable {
    case nativeUI = "NATIVE_UI"
    case webRedirect = "WEB_REDIRECT"
    case rawData = "RAW_DATA"
}

/// Surcharge information for payment methods
public struct Surcharge: Equatable {
    /// The surcharge amount
    public let amount: Double
    
    /// The currency code
    public let currency: String
    
    /// Initialize surcharge
    /// - Parameters:
    ///   - amount: Surcharge amount
    ///   - currency: Currency code
    public init(amount: Double, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

/// Currency information
public struct Currency: Equatable {
    /// Currency code (e.g., "USD", "EUR")
    public let code: String
    
    /// Currency symbol (e.g., "$", "€")
    public let symbol: String
    
    /// Initialize currency
    /// - Parameters:
    ///   - code: Currency code
    ///   - symbol: Currency symbol
    public init(code: String, symbol: String) {
        self.code = code
        self.symbol = symbol
    }
}