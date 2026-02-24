//
//  PrimerWebRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// State for web redirect payment methods (e.g., Twint).
///
/// Tracks the payment lifecycle from idle through redirect and polling to a terminal result.
///
/// ## Flow
/// ```
/// idle → loading → redirecting → polling → success | failure
/// ```
@available(iOS 15.0, *)
public struct PrimerWebRedirectState: Equatable {

    /// The current status of the web redirect payment flow.
    public enum Status: Equatable {
        /// Initial state before any action.
        case idle
        /// Payment is being prepared.
        case loading
        /// User is being redirected to the external payment page.
        case redirecting
        /// SDK is polling for the payment result after redirect.
        case polling
        /// Payment completed successfully.
        case success
        /// Payment failed with the given error message.
        case failure(String)
    }

    /// Current payment status.
    public var status: Status

    /// The payment method details, if available.
    public var paymentMethod: CheckoutPaymentMethod?

    /// Formatted surcharge amount for this payment method, if applicable.
    public var surchargeAmount: String?

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
