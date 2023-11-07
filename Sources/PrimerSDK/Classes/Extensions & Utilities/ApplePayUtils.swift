//
//  ApplePayUtils.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 07/11/2023.
//

import PassKit

private let paymentOptionsSettings = PrimerSettings.current.paymentMethodOptions.cardPaymentOptions

final class ApplePayUtils {
    
    static func supportedPKCardNetworks(cardNetworks: [CardNetwork] = CardNetwork.supportedNetworks) -> [PKPaymentNetwork] {
        return cardNetworks.compactMap { cardNetwork in
            switch cardNetwork {
            case .amex:
                return .amex
            case .cartesBancaires:
                if #available(iOS 11.2, *) {
                    return .cartesBancaires
                } else {
                    return nil
                }
            case .discover:
                return .discover
            case .elo:
                if #available(iOS 12.1.1, *) {
                    return .elo
                } else {
                    return nil
                }
            case .jcb:
                if #available(iOS 10.1, *) {
                    return .JCB
                } else {
                    return nil
                }
            case .masterCard:
                return .masterCard
            case .maestro:
                if #available(iOS 12.0, *) {
                    return .maestro
                } else {
                    return nil
                }
            case .mir:
                if #available(iOS 14.5, *) {
                    return .mir
                } else {
                    return nil
                }
            case .unionpay:
                return .chinaUnionPay
            case .visa:
                return .visa
            default:
                return nil
            }
        }
    }
}
