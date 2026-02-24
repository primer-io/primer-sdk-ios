//
//  WebRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
public struct WebRedirectState: Equatable {

    public enum Status: Equatable {
        case idle
        case loading
        case redirecting
        case polling
        case success
        case failure(String)
    }

    public var status: Status
    public var paymentMethod: CheckoutPaymentMethod?
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
