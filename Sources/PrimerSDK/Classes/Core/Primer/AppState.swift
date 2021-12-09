//
//  AppState.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

internal protocol AppStateProtocol: AnyObject {
    var paymentMethods: [PaymentMethodToken] { get set }
    var selectedPaymentMethodToken: String { get set }
    var clientToken: String? { get set }
    var decodedClientToken: DecodedClientToken? { get set }
    var primerConfiguration: PrimerConfiguration? { get set }
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
    var selectedPaymentMethodToken: String = ""
    var decodedClientToken: DecodedClientToken?
    var primerConfiguration: PrimerConfiguration?
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
