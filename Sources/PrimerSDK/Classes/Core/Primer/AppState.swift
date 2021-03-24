//
//  AppState.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

protocol AppStateProtocol: class {
    var settings: PrimerSettingsProtocol { get }
    var viewModels: [PaymentMethodViewModel] { get set }
    var paymentMethods: [PaymentMethodToken] { get set }
    var selectedPaymentMethod: String { get set }
    var decodedClientToken: DecodedClientToken? { get set }
    var paymentMethodConfig: PaymentMethodConfig? { get set }
    var accessToken: String? { get set }
    var billingAgreementToken: String? { get set }
    var orderId: String? { get set }
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? { get set }
    var approveURL: String? { get set }
    var directDebitMandate: DirectDebitMandate { get set }
    var directDebitFormCompleted: Bool { get set }
    var cardData: CardData { get set }
    var mandateId: String? { get set }
    var routerState: RouterState { get set }
    var authorizationToken: String? { get set }
    var sessionId: String? { get set }
}

class AppState: AppStateProtocol {
    
    @Dependency private(set) var settings: PrimerSettingsProtocol
    
    var viewModels: [PaymentMethodViewModel] = []
    var paymentMethods: [PaymentMethodToken] = []
    var selectedPaymentMethod: String = ""
    var decodedClientToken: DecodedClientToken?
    var paymentMethodConfig: PaymentMethodConfig?
    var accessToken: String?
    var billingAgreementToken: String?
    var orderId: String?
    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?
    var approveURL: String?
    var directDebitMandate: DirectDebitMandate = DirectDebitMandate(address: Address())
    var directDebitFormCompleted: Bool = false
    var mandateId: String?
    var cardData: CardData = CardData(name: "", number: "", expiryYear: "", expiryMonth: "", cvc: "")
    var routerState: RouterState = RouterState()
    var authorizationToken: String?
    var sessionId: String?
}

struct CardData {
    var name, number, expiryYear, expiryMonth, cvc: String
}

struct RouterState {
    var formType: FormType?
}

#endif
