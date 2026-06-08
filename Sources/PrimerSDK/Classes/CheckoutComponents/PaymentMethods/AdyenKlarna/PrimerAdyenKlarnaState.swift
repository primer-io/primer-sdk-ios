//
//  PrimerAdyenKlarnaState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Adyen Klarna flow: `idle` -> `loading` -> `optionSelection` -> `submitting` -> `redirecting` -> `polling` -> `success` | `failure`
@available(iOS 15.0, *)
struct PrimerAdyenKlarnaState: Equatable, @unchecked Sendable {

    /// When switching on this enum, always include a `default` case to handle future additions.
    enum Status: Equatable {
        case idle
        case loading
        case optionSelection
        case submitting
        case redirecting
        case polling
        case success
        case failure(String)
    }

    var status: Status
    var paymentOptions: [AdyenKlarnaPaymentOption]
    var selectedOption: AdyenKlarnaPaymentOption?
    var paymentMethod: CheckoutPaymentMethod?
    var surchargeAmount: String?

    init(
        status: Status = .idle,
        paymentOptions: [AdyenKlarnaPaymentOption] = [],
        selectedOption: AdyenKlarnaPaymentOption? = nil,
        paymentMethod: CheckoutPaymentMethod? = nil,
        surchargeAmount: String? = nil
    ) {
        self.status = status
        self.paymentOptions = paymentOptions
        self.selectedOption = selectedOption
        self.paymentMethod = paymentMethod
        self.surchargeAmount = surchargeAmount
    }
}
