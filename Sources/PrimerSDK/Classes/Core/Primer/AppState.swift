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
    var paymentMethods: [PaymentMethodToken] { get set }
    var selectedPaymentMethodId: String { get set }
    
    var billingAgreementToken: String? { get set }
    var orderId: String? { get set }
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? { get set }
    var approveURL: String? { get set }
    var directDebitMandate: DirectDebitMandate { get set }
    var directDebitFormCompleted: Bool { get set }
    var cardData: CardData { get set }
    var mandateId: String? { get set }
    var authorizationToken: String? { get set }
    var customerToken: String? { get set }
    var sessionId: String? { get set }
}

internal class AppState: AppStateProtocol {
    var clientToken: String?
    
    var paymentMethods: [PaymentMethodToken] = []
    var selectedPaymentMethodId: String = ""
    var paymentMethodConfig: PrimerConfiguration?
    
    var billingAgreementToken: String?
    var orderId: String?
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?
    var approveURL: String?
    var directDebitMandate: DirectDebitMandate = DirectDebitMandate(address: Address())
    var directDebitFormCompleted: Bool = false
    var mandateId: String?
    var cardData: CardData = CardData(name: "", number: "", expiryYear: "", expiryMonth: "", cvc: "")
    var authorizationToken: String?
    var customerToken: String?
    var sessionId: String?

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
}

struct CardData {
    var name, number, expiryYear, expiryMonth, cvc: String
}

#endif
