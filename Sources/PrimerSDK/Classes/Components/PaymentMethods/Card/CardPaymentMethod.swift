//
//  CardPaymentMethod.swift
//
//
//  Created by Boris on 6.2.25..
//

struct CardPaymentMethod: PaymentMethod {
    let id: String
    let name: String
    let methodType: PaymentMethodType = .card
}
