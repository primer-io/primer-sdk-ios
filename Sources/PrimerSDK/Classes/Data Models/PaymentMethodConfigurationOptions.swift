//
//  PaymentMethodConfigurationOptions.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol PaymentMethodOptions: Codable { }

extension PaymentMethodOptions { }

struct PayPalOptions: PaymentMethodOptions {
    let clientId: String
}

enum ApplePayRecurringInterval: String, Codable {
        case minute
        case hour
        case day
        case month
        case year
        case unknown

        var nsCalendarUnit: NSCalendar.Unit? {
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

protocol ApplePayBillingBase: Codable {
    var label: String { get }
    var amount: Int? { get }
    var recurringStartDate: Double? { get }
    var recurringEndDate: Double? { get }
    var recurringIntervalUnit: ApplePayRecurringInterval? { get }
    var recurringIntervalCount: Int? { get }
}

struct ApplePayRegularBillingOption: ApplePayBillingBase {
    let label: String
    let amount: Int?
    let recurringStartDate: Double?
    let recurringEndDate: Double?
    let recurringIntervalUnit: ApplePayRecurringInterval?
    let recurringIntervalCount: Int?
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
