//
//  PayPalPaymentMethod.swift
//
//
//  Created by Boris on 6.2.25..
//

struct PayPalPaymentMethod: PaymentMethod {
    let id: String
    let name: String
    let methodType: PaymentMethodType = .paypal
}
