//
//  PaymentResult.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Result of a payment operation.
internal struct PaymentResult {
    let paymentId: String
    let status: PaymentStatus
    let token: String?
    let redirectUrl: String?
    let errorMessage: String?
    let metadata: [String: Any]?
    
    init(
        paymentId: String,
        status: PaymentStatus,
        token: String? = nil,
        redirectUrl: String? = nil,
        errorMessage: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.paymentId = paymentId
        self.status = status
        self.token = token
        self.redirectUrl = redirectUrl
        self.errorMessage = errorMessage
        self.metadata = metadata
    }
}

/// Status of a payment.
internal enum PaymentStatus {
    case pending
    case processing
    case authorized
    case success
    case failed
    case cancelled
    case requires3DS
    case requiresAction
}