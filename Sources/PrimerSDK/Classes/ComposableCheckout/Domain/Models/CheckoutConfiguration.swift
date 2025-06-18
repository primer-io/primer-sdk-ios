//
//  CheckoutConfiguration.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// Domain model representing the configuration needed for checkout
@available(iOS 15.0, *)
internal struct CheckoutConfiguration {
    let configuration: ComposablePrimerConfiguration
    let paymentMethods: [PrimerComposablePaymentMethod]
    let currency: ComposableCurrency?

    init(
        config: ComposablePrimerConfiguration,
        paymentMethods: [PrimerComposablePaymentMethod],
        currency: ComposableCurrency? = nil
    ) {
        self.configuration = config
        self.paymentMethods = paymentMethods
        self.currency = currency
    }
}

/// Domain model for card payment data
@available(iOS 15.0, *)
internal struct CardPaymentData {
    let cardNumber: String
    let cvv: String
    let expiryDate: String
    let cardholderName: String?
    let postalCode: String?
    let countryCode: String?
    let city: String?
    let state: String?
    let addressLine1: String?
    let addressLine2: String?
    let phoneNumber: String?
    let firstName: String?
    let lastName: String?

    init(
        cardNumber: String,
        cvv: String,
        expiryDate: String,
        cardholderName: String? = nil,
        postalCode: String? = nil,
        countryCode: String? = nil,
        city: String? = nil,
        state: String? = nil,
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        phoneNumber: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil
    ) {
        self.cardNumber = cardNumber
        self.cvv = cvv
        self.expiryDate = expiryDate
        self.cardholderName = cardholderName
        self.postalCode = postalCode
        self.countryCode = countryCode
        self.city = city
        self.state = state
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
    }
}

/// Domain model for payment token
@available(iOS 15.0, *)
internal struct PaymentToken {
    let token: String
    let expirationDate: Date?
    let tokenType: String

    init(
        token: String,
        expirationDate: Date? = nil,
        tokenType: String = "card"
    ) {
        self.token = token
        self.expirationDate = expirationDate
        self.tokenType = tokenType
    }
}

/// Domain model for payment result (internal)
@available(iOS 15.0, *)
internal struct ComposablePaymentResult {
    let success: Bool
    let transactionId: String?
    let error: Error?
    let paymentStatus: PaymentStatus

    init(
        success: Bool,
        transactionId: String? = nil,
        error: Error? = nil,
        paymentStatus: PaymentStatus = .pending
    ) {
        self.success = success
        self.transactionId = transactionId
        self.error = error
        self.paymentStatus = paymentStatus
    }
}

/// Payment status enumeration
@available(iOS 15.0, *)
internal enum PaymentStatus {
    case pending
    case authorized
    case captured
    case failed
    case cancelled
    case declined
}
