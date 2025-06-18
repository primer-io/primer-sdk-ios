//
//  PrimerComposablePaymentMethod.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Simple payment method model that matches Android's PrimerComposablePaymentMethod exactly
public struct PrimerComposablePaymentMethod: Identifiable, Equatable, Hashable {
    /// Unique identifier (derived from paymentMethodType)
    public var id: String { paymentMethodType }
    
    /// The payment method type identifier (matches Android exactly)
    public let paymentMethodType: String
    
    /// Display name for the payment method (optional, matches Android)
    public let paymentMethodName: String?
    
    /// Description text for the payment method (optional, matches Android)
    public let description: String?
    
    /// Icon URL for the payment method (optional, matches Android)
    public let iconUrl: String?
    
    /// Surcharge information (optional, matches Android)
    public let surcharge: PrimerComposablePaymentMethodSurcharge?
    
    /// Initialize a new payment method (simplified constructor matching Android)
    /// - Parameters:
    ///   - paymentMethodType: The payment method type identifier
    ///   - paymentMethodName: Display name (optional)
    ///   - description: Description text (optional)
    ///   - iconUrl: Icon URL (optional)
    ///   - surcharge: Surcharge information (optional)
    public init(
        paymentMethodType: String,
        paymentMethodName: String? = nil,
        description: String? = nil,
        iconUrl: String? = nil,
        surcharge: PrimerComposablePaymentMethodSurcharge? = nil
    ) {
        self.paymentMethodType = paymentMethodType
        self.paymentMethodName = paymentMethodName
        self.description = description
        self.iconUrl = iconUrl
        self.surcharge = surcharge
    }
    
    /// Equatable implementation
    public static func == (lhs: PrimerComposablePaymentMethod, rhs: PrimerComposablePaymentMethod) -> Bool {
        return lhs.paymentMethodType == rhs.paymentMethodType &&
               lhs.paymentMethodName == rhs.paymentMethodName &&
               lhs.description == rhs.description &&
               lhs.iconUrl == rhs.iconUrl &&
               lhs.surcharge == rhs.surcharge
    }
    
    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(paymentMethodType)
        hasher.combine(paymentMethodName)
        hasher.combine(description)
        hasher.combine(iconUrl)
        hasher.combine(surcharge)
    }
}

// MARK: - Supporting Models (matching Android)

/// Surcharge information for payment methods (matches Android exactly)
public struct PrimerComposablePaymentMethodSurcharge: Equatable, Hashable {
    /// The surcharge amount
    public let amount: Int
    
    /// The currency code
    public let currency: String
    
    /// Initialize surcharge
    /// - Parameters:
    ///   - amount: Surcharge amount in smallest currency unit (e.g., cents)
    ///   - currency: Currency code (e.g., "USD", "EUR")
    public init(amount: Int, currency: String) {
        self.amount = amount
        self.currency = currency
    }
    
    /// Equatable implementation
    public static func == (lhs: PrimerComposablePaymentMethodSurcharge, rhs: PrimerComposablePaymentMethodSurcharge) -> Bool {
        return lhs.amount == rhs.amount && lhs.currency == rhs.currency
    }
    
    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(currency)
    }
}

/// Currency information (matches Android exactly)
public struct ComposableCurrency: Equatable, Hashable {
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
    
    /// Equatable implementation
    public static func == (lhs: ComposableCurrency, rhs: ComposableCurrency) -> Bool {
        return lhs.code == rhs.code && lhs.symbol == rhs.symbol
    }
    
    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(symbol)
    }
}