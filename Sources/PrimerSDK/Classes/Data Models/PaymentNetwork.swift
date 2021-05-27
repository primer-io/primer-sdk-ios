//
//  PaymentNetwork.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/4/21.
//

#if canImport(UIKit)

import Foundation
import PassKit

public enum PaymentNetwork: String {
    
    case chinaUnionPay
    case discover
    case eftpos
    case electron
    case elo
    case idCredit
    case interac
    case jcb
    case mada
    case maestro
    case masterCard
    case privateLabel
    case quicPay
    case suica
    case visa
    case vPay
    case barcode
    case girocard
    
    var applePayPaymentNetwork: PKPaymentNetwork? {
        switch self {
        case .chinaUnionPay:
            return .chinaUnionPay
        case .discover:
            return .discover
        case .eftpos:
            if #available(iOS 12.0, *) {
                return .eftpos
            } else {
                return nil
            }
        case .electron:
            if #available(iOS 12.0, *) {
                return .electron
            } else {
                return nil
            }
        case .elo:
            if #available(iOS 12.1.1, *) {
                return .elo
            } else {
                return nil
            }
        case .idCredit:
            if #available(iOS 10.3, *) {
                return .idCredit
            } else {
                return nil
            }
        case .interac:
            return .interac
        case .jcb:
            if #available(iOS 10.1, *) {
                return .JCB
            } else {
                return nil
            }
        case .mada:
            if #available(iOS 12.1.1, *) {
                return .mada
            } else {
                return nil
            }
        case .maestro:
            if #available(iOS 12.0, *) {
                return .maestro
            } else {
                return nil
            }
        case .masterCard:
            return .masterCard
        case .privateLabel:
            return .privateLabel
        case .quicPay:
            if #available(iOS 10.3, *) {
                return .quicPay
            } else {
                return nil
            }
        case .suica:
            if #available(iOS 10.1, *) {
                return .suica
            } else {
                return nil
            }
        case .visa:
            return .visa
        case .vPay:
            if #available(iOS 12.0, *) {
                return .vPay
            } else {
                return nil
            }
        case .barcode:
            if #available(iOS 14.0, *) {
                return .barcode
            } else {
                return nil
            }
        case .girocard:
            if #available(iOS 14.0, *) {
                return .girocard
            } else {
                return nil
            }
        }
    }
    
}

#endif
