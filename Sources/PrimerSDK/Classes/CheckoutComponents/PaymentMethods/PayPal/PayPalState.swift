//
//  PayPalState.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// State model for PayPal payment method scope.
/// Tracks the current status of the PayPal payment flow.
@available(iOS 15.0, *)
public struct PayPalState: Equatable {

    /// The current status of the PayPal payment flow.
    public enum Status: Equatable {
        /// Initial state, ready to start payment
        case idle
        /// Creating PayPal session
        case loading
        /// Web authentication session is open
        case redirecting
        /// Processing payment after user approval
        case processing
        /// Payment completed successfully
        case success
        /// Payment failed with error message
        case failure(String)
    }

    /// Current status of the PayPal flow
    public var status: Status

    /// The PayPal payment method information
    public var paymentMethod: CheckoutPaymentMethod?

    /// Formatted surcharge amount if applicable (e.g., "+ $1.50")
    public var surchargeAmount: String?

    /// Default initializer
    public init(
        status: Status = .idle,
        paymentMethod: CheckoutPaymentMethod? = nil,
        surchargeAmount: String? = nil
    ) {
        self.status = status
        self.paymentMethod = paymentMethod
        self.surchargeAmount = surchargeAmount
    }
}
