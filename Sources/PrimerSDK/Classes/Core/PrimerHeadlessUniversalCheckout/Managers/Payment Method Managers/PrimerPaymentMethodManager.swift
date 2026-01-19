//
//  PrimerPaymentMethodManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public enum PrimerPaymentMethodManagerCategory: String {
    case nativeUI               = "NATIVE_UI"
    case rawData                = "RAW_DATA"
    case nolPay                 = "NOL_PAY"
    case componentWithRedirect  = "COMPONENT_WITH_REDIRECT"
    case stripeAch              = "STRIPE_ACH"
    case klarna                 = "KLARNA"
}

protocol PrimerPaymentMethodManager {

    var paymentMethodType: String { get }

    init(paymentMethodType: String) throws
    func showPaymentMethod(intent: PrimerSessionIntent) throws
}
