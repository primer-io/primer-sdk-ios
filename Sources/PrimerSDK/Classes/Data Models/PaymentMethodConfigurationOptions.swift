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

struct CardOptions: PaymentMethodOptions {
    let threeDSecureEnabled: Bool
    let threeDSecureToken: String?
    let threeDSecureInitUrl: String?
    let threeDSecureProvider: String
    let processorConfigId: String?
}

struct MerchantOptions: PaymentMethodOptions {
    let merchantId: String
    let merchantAccountId: String
    let appId: String? // Nol pay, Klarna
}

struct ExtraMerchantData: PaymentMethodOptions {
    var extraMerchantData: String?

    enum CodingKeys: String, CodingKey {
        case extraMerchantData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let extraMerchantData = try container.decodeIfPresent([String: Any].self, forKey: .extraMerchantData) {
            let jsonData = try JSONSerialization.data(withJSONObject: extraMerchantData, options: [])
            self.extraMerchantData = String(data: jsonData, encoding: .utf8)
        } else {
            self.extraMerchantData = nil
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
