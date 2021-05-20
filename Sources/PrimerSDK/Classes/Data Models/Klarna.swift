//
//  Klarna.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//

import Foundation

public enum KlarnaSessionType: String, Codable {
    case hostedPaymentPage = "HOSTED_PAYMENT_PAGE"
    case recurringPayment = "RECURRING_PAYMENT"
}

public struct LocaleData: Codable {
    let languageCode: String?
    var localeCode: String?
    let regionCode: String?
    
    public init(languageCode: String?, regionCode: String?) {
        self.languageCode = languageCode ?? Locale.current.languageCode
        self.regionCode = regionCode ?? Locale.current.regionCode
        
        if let languageCode = self.languageCode {
            if let regionCode = self.regionCode {
                self.localeCode = "\(languageCode)-\(regionCode)"
            } else {
                self.localeCode = "\(languageCode)"
            }
        }
    }
}

// MARK: CREATE PAYMENT SESSION DATA MODELS

struct KlarnaCreatePaymentSessionAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionType: KlarnaSessionType
    var localeData: LocaleData?
    let description: String?
    let redirectUrl: String?
    let totalAmount: Int?
    let orderItems: [OrderItem]?
}

struct KlarnaCreatePaymentSessionAPIResponse: Codable {
    var sessionType: KlarnaSessionType {
        return hppSessionId == nil ? .recurringPayment : .hostedPaymentPage
    }
    let clientToken: String
    let sessionId: String
    let categories: [KlarnaSessionCategory]
    let hppSessionId: String?
    let hppRedirectUrl: String
}

// MARK: CREATE CUSTOMER TOKEN DATA MODELS

struct CreateKlarnaCustomerTokenAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionId: String
    let authorizationToken: String
    let description: String?
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

public struct KlarnaSessionOrderLines: Codable {
    public let type: String?
    public let name: String?
    public let quantity: Int?
    public let unitPrice: Int?
    public let totalAmount: Int?
    public let totalDiscountAmount: Int?

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case name = "name"
        case quantity = "quantity"
        case unitPrice = "unit_price"
        case totalAmount = "total_amount"
        case totalDiscountAmount = "total_discount_amount"
    }
}

struct KlarnaSessionMerchantUrls: Codable {
    let statusUpdate: String
}

struct KlarnaSessionOptions: Codable {
    let disableConfirmationModals: Bool
}

public struct KlarnaSessionData: Codable {
    public let recurringDescription: String?
    public let purchaseCountry: String?
    public let purchaseCurrency: String?
    public let locale: String?
    public let orderAmount: Int?
    public let orderLines: [KlarnaSessionOrderLines]
    public let billingAddress: KlarnaBillingAddress?
}

public struct KlarnaBillingAddress: Codable {
    public let addressLine1: String?
    public let addressLine2: String?
    public let addressLine3: String?
    public let city: String?
    public let countryCode: String?
    public let email: String?
    public let firstName: String?
    public let lastName: String?
    public let phoneNumber: String?
    public let postalCode: String?
    public let state: String?
    public let title: String?
}

struct KlarnaFinalizePaymentSessionresponse: Codable {
    let sessionData: KlarnaSessionData
}
