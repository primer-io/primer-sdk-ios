//
//  PaymentMethodConfigurationOptions.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/12/21.
//

import Foundation

protocol PaymentMethodOptions: Codable { }

extension PaymentMethodOptions { }

struct PayPalOptions: PaymentMethodOptions {
    let clientId: String
}

struct ApplePayRecurringInterval {
    enum Unit: String, Codable {
        case minute, hour, day, month, year, unknown
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try? container.decode(String.self)
            self = Unit(rawValue: value ?? "") ?? .unknown
        }
        var nsCalendarUnit: NSCalendar.Unit? {
            switch self {
            case .minute: return .minute
            case .hour: return .hour
            case .day: return .day
            case .month: return .month
            case .year: return .year
            case .unknown: return nil
            }
        }
    }
}

// Base Billing Option Protocol
protocol ApplePayBillingBase: Codable {
    var label: String { get }
    var amount: Int? { get }
    var recurringStartDate: Date? { get }
    var recurringEndDate: Date? { get }
    var recurringIntervalUnit: ApplePayRecurringInterval.Unit? { get }
    var recurringIntervalCount: Int? { get }
}

// Regular Billing Option
struct ApplePayRegularBillingOption: ApplePayBillingBase {
    let label: String
    let amount: Int?
    let recurringStartDate: Date?
    let recurringEndDate: Date?
    let recurringIntervalUnit: ApplePayRecurringInterval.Unit?
    let recurringIntervalCount: Int?
}

// Trial Billing Option
struct ApplePayTrialBillingOption: ApplePayBillingBase {
    let label: String
    var amount: Int?
    let recurringStartDate: Date?
    let recurringEndDate: Date?
    let recurringIntervalUnit: ApplePayRecurringInterval.Unit?
    let recurringIntervalCount: Int?
}

// Deferred Billing Option
struct ApplePayDeferredBillingOption: Codable {
    let label: String
    let amount: Int?
    let deferredPaymentDate: Date
}

// Automatic Reload Billing Option
struct ApplePayAutomaticReloadBillingOption: Codable {
    let label: String
    let amount: Int?
    let automaticReloadThresholdAmount: Int
}

// Payment Request Base
protocol ApplePayPaymentRequestBase: Codable {
    var paymentDescription: String? { get }
    var billingAgreement: String? { get }
    var managementUrl: String { get }
    var tokenManagementUrl: String? { get }
}

// Recurring Payment Request
struct ApplePayRecurringPaymentRequest: ApplePayPaymentRequestBase {
    let paymentDescription: String?
    let billingAgreement: String?
    let managementUrl: String
    let regularBilling: ApplePayRegularBillingOption
    let trialBilling: ApplePayTrialBillingOption?
    let tokenManagementUrl: String?
}

// Deferred Payment Request
struct ApplePayDeferredPaymentRequest: ApplePayPaymentRequestBase {
    let paymentDescription: String?
    let billingAgreement: String?
    let managementUrl: String
    let deferredBilling: ApplePayDeferredBillingOption
    let freeCancellationDate: Date?
    let freeCancellationTimeZone: String?
    let tokenManagementUrl: String?
}

// Automatic Reload Request
struct ApplePayAutomaticReloadRequest: ApplePayPaymentRequestBase {
    let paymentDescription: String?
    let billingAgreement: String?
    let managementUrl: String
    let automaticReloadBilling: ApplePayAutomaticReloadBillingOption
    let tokenManagementUrl: String?
}

struct ApplePayOptions: PaymentMethodOptions {
    let merchantName: String?
    let recurringPaymentRequest: ApplePayRecurringPaymentRequest?
    let deferredPaymentRequest: ApplePayDeferredPaymentRequest?
    let automaticReloadRequest: ApplePayAutomaticReloadRequest?
}

struct CardOptions: PaymentMethodOptions {
    let threeDSecureEnabled: Bool
    let threeDSecureToken: String?
    let threeDSecureInitUrl: String?
    let threeDSecureProvider: String
    let processorConfigId: String?
    let captureVaultedCardCvv: Bool?
}

struct MerchantOptions: PaymentMethodOptions {
    let merchantId: String
    let merchantAccountId: String
    let appId: String? // Nol pay
    let extraMerchantData: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case merchantId, merchantAccountId, appId, extraMerchantData
    }

    init(merchantId: String, merchantAccountId: String, appId: String?, extraMerchantData: [String: Any]? = nil) {
        self.merchantId = merchantId
        self.merchantAccountId = merchantAccountId
        self.appId = appId
        self.extraMerchantData = extraMerchantData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        merchantId = try container.decode(String.self, forKey: .merchantId)
        merchantAccountId = try container.decode(String.self, forKey: .merchantAccountId)
        appId = try container.decodeIfPresent(String.self, forKey: .appId)
        extraMerchantData = try container.decodeIfPresent([String: Any].self, forKey: .extraMerchantData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let extraMerchantData = extraMerchantData {
            let jsonData = try JSONSerialization.data(withJSONObject: extraMerchantData, options: [])
            try container.encode(jsonData, forKey: .extraMerchantData)
        }
    }
}

extension PrimerTestPaymentMethodSessionInfo.FlowDecision {

    var displayFlowTitle: String {
        switch self {
        case .success:
            return Strings.PrimerTestFlowDecision.successTitle
        case .decline:
            return Strings.PrimerTestFlowDecision.declineTitle
        case .fail:
            return Strings.PrimerTestFlowDecision.failTitle
        }
    }

}
