//
//  PaymentResult.swift
//
//
//  Created by Boris on 6.2.25..
//

/// The result returned when a payment is processed.
struct PaymentResult {
    let success: Bool
    let message: String?
    // TODO: Add error codes or more detailed response if required.
}
