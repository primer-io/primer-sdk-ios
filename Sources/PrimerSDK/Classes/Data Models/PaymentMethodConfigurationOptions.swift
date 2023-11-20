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
