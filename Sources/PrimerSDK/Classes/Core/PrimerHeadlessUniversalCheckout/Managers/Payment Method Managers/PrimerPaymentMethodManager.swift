//
//  PrimerPaymentMethodManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 26/9/22.
//

import Foundation

public enum PrimerPaymentMethodManagerCategory: String {
    case nativeUI               = "NATIVE_UI"
    case rawData                = "RAW_DATA"
    case nolPay                 = "NOL_PAY"
    case componentWithRedirect  = "COMPONENT_WITH_REDIRECT"
    case stripeAch              = "STRIPE_ACH"
    case klarna                 = "KLARNA"
}

internal protocol PrimerPaymentMethodManager {

    var paymentMethodType: String { get }

    init(paymentMethodType: String) throws
    func showPaymentMethod(intent: PrimerSessionIntent) throws
}
