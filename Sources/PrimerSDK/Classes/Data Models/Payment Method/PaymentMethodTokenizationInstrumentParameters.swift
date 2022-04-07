//
//  PaymentMethodTokenizationInstrumentParameters.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/4/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentMethodTokenizationInstrumentParameters: Codable {}

struct PaymentCardTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let number: String
    let cvv: String
    let expirationMonth: String
    let expirationYear: String
    let cardholderName: String?
}

struct PayPalTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let paypalOrderId: String?
    let paypalBillingAgreementId: String?
    let shippingAddress: ShippingAddress?
    let externalPayerInfo: ExternalPayerInfo?
}

struct ApplePayTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let paymentMethodConfigId: String
    let token: ApplePayPaymentResponseToken
    let sourceConfig: ApplePaySourceConfig
}

struct GoCardlessTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let gocardlessMandateId: String
}

struct KlarnaAuthTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let klarnaAuthorizationToken: String
}

struct KlarnaCustomerTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let klarnaCustomerToken: String
    let sessionData: KlarnaSessionData
}

struct ApayaTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let currencyCode: String
    let hashedIdentifier: String
    let mcc: String
    let mnc: String
    let mx: String
    let productId: String
}

struct DotPayTokenizationInstrumentParameters: PaymentMethodTokenizationInstrumentParameters {
    let sessionInfo: BankSelectorSessionInfo
    let type: String = "OFF_SESSION_PAYMENT"
    let paymentMethodType: String
}

#endif


