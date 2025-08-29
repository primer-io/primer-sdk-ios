//
//  PaymentResult.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Result of a payment operation.
public struct PaymentResult {
    public let paymentId: String
    public let status: PaymentStatus
    public let token: String?
    public let redirectUrl: String?
    public let errorMessage: String?
    public let metadata: [String: Any]?
    public let amount: Int?
    public let paymentMethodType: String?

    public init(
        paymentId: String,
        status: PaymentStatus,
        token: String? = nil,
        redirectUrl: String? = nil,
        errorMessage: String? = nil,
        metadata: [String: Any]? = nil,
        amount: Int? = nil,
        paymentMethodType: String? = nil
    ) {
        self.paymentId = paymentId
        self.status = status
        self.token = token
        self.redirectUrl = redirectUrl
        self.errorMessage = errorMessage
        self.metadata = metadata
        self.amount = amount
        self.paymentMethodType = paymentMethodType
    }
}

/// Status of a payment.
public enum PaymentStatus {
    case pending
    case processing
    case authorized
    case success
    case failed
    case cancelled
    case requires3DS
    case requiresAction
}
