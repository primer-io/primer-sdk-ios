//
//  AppState.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

internal protocol AppStateProtocol: AnyObject {
    
    var clientToken: String? { get set }
    var primerConfiguration: PrimerConfiguration? { get set }
    var paymentMethods: [PaymentMethodToken] { get set }
    var selectedPaymentMethodToken: String? { get set }
    var selectedPaymentMethod: PaymentMethodToken? { get }
    
}

internal class AppState: AppStateProtocol {
    
    var clientToken: String?
    var primerConfiguration: PrimerConfiguration?
    var paymentMethods: [PaymentMethodToken] = []
    var selectedPaymentMethodToken: String?
    var selectedPaymentMethod: PaymentMethodToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let selectedPaymentMethodToken = selectedPaymentMethodToken else { return nil }
        return state.paymentMethods.first(where: { $0.token == selectedPaymentMethodToken })
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
}

struct CardData {
    var name, number, expiryYear, expiryMonth, cvc: String
}

#endif
