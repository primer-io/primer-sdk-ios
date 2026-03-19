//
//  PaymentMethodOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public protocol PaymentMethodOptions: Codable { }

public extension PaymentMethodOptions { }

public struct PayPalOptions: PaymentMethodOptions {
    public let clientId: String

    public init(clientId: String) {
        self.clientId = clientId
    }
}

public enum ApplePayRecurringInterval: String, Codable {
    case minute
    case hour
    case day
    case month
    case year
    case unknown

    public var nsCalendarUnit: NSCalendar.Unit? {
        switch self {
        case .minute: .minute
        case .hour: .hour
        case .day: .day
        case .month: .month
        case .year: .year
        case .unknown: nil
        }
    }
}

public protocol ApplePayBillingBase: Codable {
    var label: String { get }
    var amount: Int? { get }
    var recurringStartDate: Double? { get }
    var recurringEndDate: Double? { get }
    var recurringIntervalUnit: ApplePayRecurringInterval? { get }
    var recurringIntervalCount: Int? { get }
}

public struct ApplePayRegularBillingOption: ApplePayBillingBase {
    public let label: String
    public let amount: Int?
    public let recurringStartDate: Double?
    public let recurringEndDate: Double?
    public let recurringIntervalUnit: ApplePayRecurringInterval?
    public let recurringIntervalCount: Int?

    public init(
        label: String,
        amount: Int?,
        recurringStartDate: Double?,
        recurringEndDate: Double?,
        recurringIntervalUnit: ApplePayRecurringInterval?,
        recurringIntervalCount: Int?
    ) {
        self.label = label
        self.amount = amount
        self.recurringStartDate = recurringStartDate
        self.recurringEndDate = recurringEndDate
        self.recurringIntervalUnit = recurringIntervalUnit
        self.recurringIntervalCount = recurringIntervalCount
    }
}

public struct CardOptions: PaymentMethodOptions {
    public let threeDSecureEnabled: Bool
    public let threeDSecureToken: String?
    public let threeDSecureInitUrl: String?
    public let threeDSecureProvider: String
    public let processorConfigId: String?
    public let captureVaultedCardCvv: Bool?

    public init(
        threeDSecureEnabled: Bool,
        threeDSecureToken: String?,
        threeDSecureInitUrl: String?,
        threeDSecureProvider: String,
        processorConfigId: String?,
        captureVaultedCardCvv: Bool?
    ) {
        self.threeDSecureEnabled = threeDSecureEnabled
        self.threeDSecureToken = threeDSecureToken
        self.threeDSecureInitUrl = threeDSecureInitUrl
        self.threeDSecureProvider = threeDSecureProvider
        self.processorConfigId = processorConfigId
        self.captureVaultedCardCvv = captureVaultedCardCvv
    }
}

public struct MerchantOptions: PaymentMethodOptions {
    public let merchantId: String
    public let merchantAccountId: String
    public let appId: String? // Nol pay
    public let extraMerchantData: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case merchantId, merchantAccountId, appId, extraMerchantData
    }

    public init(merchantId: String, merchantAccountId: String, appId: String?, extraMerchantData: [String: Any]? = nil) {
        self.merchantId = merchantId
        self.merchantAccountId = merchantAccountId
        self.appId = appId
        self.extraMerchantData = extraMerchantData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        merchantId = try container.decode(String.self, forKey: .merchantId)
        merchantAccountId = try container.decode(String.self, forKey: .merchantAccountId)
        appId = try container.decodeIfPresent(String.self, forKey: .appId)
        extraMerchantData = try container.decodeIfPresent([String: Any].self, forKey: .extraMerchantData)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let extraMerchantData = extraMerchantData {
            let jsonData = try JSONSerialization.data(withJSONObject: extraMerchantData, options: [])
            try container.encode(jsonData, forKey: .extraMerchantData)
        }
    }
}

// MARK: - Apple Pay Billing & Request Types

public protocol ApplePayPaymentRequestBase: Codable {
    var paymentDescription: String? { get }
    var billingAgreement: String? { get }
    var managementUrl: String { get }
    var tokenManagementUrl: String? { get }
}

public struct ApplePayTrialBillingOption: ApplePayBillingBase {
    public let label: String
    public let amount: Int?
    public let recurringStartDate: Double?
    public let recurringEndDate: Double?
    public let recurringIntervalUnit: ApplePayRecurringInterval?
    public let recurringIntervalCount: Int?

    public init(
        label: String,
        amount: Int?,
        recurringStartDate: Double?,
        recurringEndDate: Double?,
        recurringIntervalUnit: ApplePayRecurringInterval?,
        recurringIntervalCount: Int?
    ) {
        self.label = label
        self.amount = amount
        self.recurringStartDate = recurringStartDate
        self.recurringEndDate = recurringEndDate
        self.recurringIntervalUnit = recurringIntervalUnit
        self.recurringIntervalCount = recurringIntervalCount
    }
}

public struct ApplePayDeferredBillingOption: Codable {
    public let label: String
    public let amount: Int?
    public let deferredPaymentDate: Double

    public init(label: String, amount: Int?, deferredPaymentDate: Double) {
        self.label = label
        self.amount = amount
        self.deferredPaymentDate = deferredPaymentDate
    }
}

public struct ApplePayAutomaticReloadBillingOption: Codable {
    public let label: String
    public let amount: Int?
    public let automaticReloadThresholdAmount: Int

    public init(label: String, amount: Int?, automaticReloadThresholdAmount: Int) {
        self.label = label
        self.amount = amount
        self.automaticReloadThresholdAmount = automaticReloadThresholdAmount
    }
}

public struct ApplePayRecurringPaymentRequest: ApplePayPaymentRequestBase {
    public let paymentDescription: String?
    public let billingAgreement: String?
    public let managementUrl: String
    public let regularBilling: ApplePayRegularBillingOption
    public let trialBilling: ApplePayTrialBillingOption?
    public let tokenManagementUrl: String?

    public init(
        paymentDescription: String?,
        billingAgreement: String?,
        managementUrl: String,
        regularBilling: ApplePayRegularBillingOption,
        trialBilling: ApplePayTrialBillingOption?,
        tokenManagementUrl: String?
    ) {
        self.paymentDescription = paymentDescription
        self.billingAgreement = billingAgreement
        self.managementUrl = managementUrl
        self.regularBilling = regularBilling
        self.trialBilling = trialBilling
        self.tokenManagementUrl = tokenManagementUrl
    }
}

public struct ApplePayDeferredPaymentRequest: ApplePayPaymentRequestBase {
    public let paymentDescription: String?
    public let billingAgreement: String?
    public let managementUrl: String
    public let deferredBilling: ApplePayDeferredBillingOption
    public let freeCancellationDate: Double?
    public let freeCancellationTimeZone: String?
    public let tokenManagementUrl: String?

    public init(
        paymentDescription: String?,
        billingAgreement: String?,
        managementUrl: String,
        deferredBilling: ApplePayDeferredBillingOption,
        freeCancellationDate: Double?,
        freeCancellationTimeZone: String?,
        tokenManagementUrl: String?
    ) {
        self.paymentDescription = paymentDescription
        self.billingAgreement = billingAgreement
        self.managementUrl = managementUrl
        self.deferredBilling = deferredBilling
        self.freeCancellationDate = freeCancellationDate
        self.freeCancellationTimeZone = freeCancellationTimeZone
        self.tokenManagementUrl = tokenManagementUrl
    }
}

public struct ApplePayAutomaticReloadRequest: ApplePayPaymentRequestBase {
    public let paymentDescription: String?
    public let billingAgreement: String?
    public let managementUrl: String
    public let automaticReloadBilling: ApplePayAutomaticReloadBillingOption
    public let tokenManagementUrl: String?

    public init(
        paymentDescription: String?,
        billingAgreement: String?,
        managementUrl: String,
        automaticReloadBilling: ApplePayAutomaticReloadBillingOption,
        tokenManagementUrl: String?
    ) {
        self.paymentDescription = paymentDescription
        self.billingAgreement = billingAgreement
        self.managementUrl = managementUrl
        self.automaticReloadBilling = automaticReloadBilling
        self.tokenManagementUrl = tokenManagementUrl
    }
}

public struct ApplePayOptions: PaymentMethodOptions {
    public let merchantName: String?
    public let recurringPaymentRequest: ApplePayRecurringPaymentRequest?
    public let deferredPaymentRequest: ApplePayDeferredPaymentRequest?
    public let automaticReloadRequest: ApplePayAutomaticReloadRequest?

    public init(
        merchantName: String?,
        recurringPaymentRequest: ApplePayRecurringPaymentRequest?,
        deferredPaymentRequest: ApplePayDeferredPaymentRequest?,
        automaticReloadRequest: ApplePayAutomaticReloadRequest?
    ) {
        self.merchantName = merchantName
        self.recurringPaymentRequest = recurringPaymentRequest
        self.deferredPaymentRequest = deferredPaymentRequest
        self.automaticReloadRequest = automaticReloadRequest
    }
}
