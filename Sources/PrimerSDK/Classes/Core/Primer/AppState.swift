//
//  AppState.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

internal protocol AppStateProtocol: AnyObject {
    var clientToken: String? { get set }
    var paymentMethodConfig: PrimerConfiguration? { get set }
    var paymentMethods: [PaymentMethod] { get set }
    var selectedPaymentMethod: String { get set }
    
    
    var billingAgreementToken: String? { get set }
    var orderId: String? { get set }
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? { get set }
    var approveURL: String? { get set }
    var authorizationToken: String? { get set }
    var customerToken: String? { get set }
    var sessionId: String? { get set }
}

internal class AppState: AppStateProtocol {
    var clientToken: String?
    var paymentMethods: [PaymentMethod] = []
    var selectedPaymentMethod: String = ""
    var paymentMethodConfig: PrimerConfiguration?
    var billingAgreementToken: String?
    var orderId: String?
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?
    var approveURL: String?
    var authorizationToken: String?
    var customerToken: String?
    var sessionId: String?

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
}

#endif
