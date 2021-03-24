//
//  Klarna.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//

import Foundation

struct LocaleData: Codable {
    let countryCode: String
    let currencyCode: String
    let localeCode: String
}

// MARK: CREATE PAYMENT SESSION DATA MODELS

struct KlarnaCreatePaymentSessionAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionType: String
    let redirectUrl: String
    let totalAmount: Int
    let localeData: LocaleData
    let orderItems: [OrderItem]
}

struct KlarnaCreatePaymentSessionAPIResponse: Codable {
    let clientToken: String
    let sessionId: String
    let categories: [KlarnaSessionCategory]
    let hppSessionId: String
    let hppRedirectUrl: String
}

// MARK: CREATE CUSTOMER TOKEN DATA MODELS

struct CreateKlarnaCustomerTokenAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionId: String
    let authorizationToken: String
    let description: String
    let localeData: LocaleData
}

struct KlarnaCustomerTokenAPIResponse: Codable {
    let customerTokenId: String
    let sessionData: KlarnaSessionData
}

// MARK: FINALIZE PAYMENT SESSION DATA MODELS

struct KlarnaFinalizePaymentSessionRequest: Codable {
    let paymentMethodConfigId: String
    let sessionId: String
}

struct KlarnaSessionCategory: Codable {
    let identifier: String
    let name: String
    let descriptiveAssetUrl: String
    let standardAssetUrl: String
}

struct KlarnaSessionOrderLines: Codable {
    let type: String?
    let name: String?
    let quantity: Int?
    let unitPrice: Int?
    let totalAmount: Int?
    let totalDiscountAmount: Int?
}

struct KlarnaSessionMerchantUrls: Codable {
    let statusUpdate: String
}

struct KlarnaSessionOptions: Codable {
    let disableConfirmationModals: Bool
}

struct KlarnaSessionData: Codable {
    let purchaseCountry: String?
    let purchaseCurrency: String?
    let locale: String?
    let orderAmount: Int?
    let orderLines: [KlarnaSessionOrderLines]
    let billingAddress: KlarnaBillingAddress?
}

struct KlarnaBillingAddress: Codable {
    let addressLine1: String?
    let addressLine2: String?
    let addressLine3: String?
    let city: String?
    let countryCode: String?
    let email: String?
    let firstName: String?
    let lastName: String?
    let phoneNumber: String?
    let postalCode: String?
    let state: String?
    let title: String?
}

struct KlarnaFinalizePaymentSessionresponse: Codable {
    let sessionData: KlarnaSessionData
}
