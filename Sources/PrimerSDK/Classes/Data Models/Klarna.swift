//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

public enum KlarnaSessionType: String, Codable {
    case hostedPaymentPage = "HOSTED_PAYMENT_PAGE"
    case recurringPayment = "RECURRING_PAYMENT"
}

public struct PrimerLocaleData: Codable {
    let languageCode: String
    let localeCode: String
    let regionCode: String?
    
    public init(languageCode: String? = nil, regionCode: String? = nil) {
        self.languageCode = (languageCode ?? Locale.current.languageCode) ?? "en"
        self.regionCode = regionCode ?? Locale.current.regionCode
        
        if let regionCode = self.regionCode {
            self.localeCode = "\(self.languageCode)-\(regionCode)"
        } else {
            self.localeCode = self.languageCode
        }
    }
}

// MARK: CREATE PAYMENT SESSION DATA MODELS

struct KlarnaCreatePaymentSessionAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionType: KlarnaSessionType
    var localeData: PrimerLocaleData?
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
    let localeData: PrimerLocaleData
}

struct KlarnaCustomerTokenAPIResponse: Codable {
    let customerTokenId: String?
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
    public let tokenDetails: KlarnaSessionDataTokenDetails?
}

public struct KlarnaSessionDataTokenDetails: Codable {
    public let brand: String?
    public let maskedNumber: String?
    public let type: String
    public let expiryDate: String?
    
    enum CodingKeys: String, CodingKey {
        case brand = "brand"
        case maskedNumber = "masked_number"
        case type = "type"
        case expiryDate = "expiry_date"
    }
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

#endif
