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
    let appId: String? // Nol pay
    let extraMerchantData: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case merchantId, merchantAccountId, appId, extraMerchantData
    }
    
    init(merchantId: String, merchantAccountId: String, appId: String?, extraMerchantData: [String: Any]?) {
        self.merchantId = merchantId
        self .merchantAccountId = merchantAccountId
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
