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
    
    @available(iOS 12.0, *)
    case eftpos
    
    @available(iOS 12.0, *)
    case electron
    
    @available(iOS 12.1.1, *)
    case elo

    @available(iOS 10.3, *)
    case idCredit
    
    case interac

    @available(iOS 10.1, *)
    case jcb

    @available(iOS 12.1.1, *)
    case mada

    @available(iOS 12.0, *)
    case maestro

    case masterCard
    
    case privateLabel

    @available(iOS 10.3, *)
    case quicPay

    @available(iOS 10.1, *)
    case suica

    case visa

    @available(iOS 12.0, *)
    case vPay

    @available(iOS 14.0, *)
    case barcode

    @available(iOS 14.0, *)
    case girocard
    
    var applePayPaymentNetwork: PKPaymentNetwork {
        switch self {
        case .chinaUnionPay:
            return .chinaUnionPay
        case .discover:
            return .discover
        case .eftpos:
            if #available(iOS 12.0, *) {
                return .eftpos
            } else {
                fatalError()
            }
        case .electron:
            if #available(iOS 12.0, *) {
                return .electron
            } else {
                fatalError()
            }
        case .elo:
            if #available(iOS 12.1.1, *) {
                return .elo
            } else {
                fatalError()
            }
        case .idCredit:
            if #available(iOS 10.3, *) {
                return .idCredit
            } else {
                fatalError()
            }
        case .interac:
            return .interac
        case .jcb:
            if #available(iOS 10.1, *) {
                return .JCB
            } else {
                fatalError()
            }
        case .mada:
            if #available(iOS 12.1.1, *) {
                return .mada
            } else {
                fatalError()
            }
        case .maestro:
            if #available(iOS 12.0, *) {
                return .maestro
            } else {
                fatalError()
            }
        case .masterCard:
            return .masterCard
        case .privateLabel:
            return .privateLabel
        case .quicPay:
            if #available(iOS 10.3, *) {
                return .quicPay
            } else {
                fatalError()
            }
        case .suica:
            if #available(iOS 10.1, *) {
                return .suica
            } else {
                fatalError()
            }
        case .visa:
            return .visa
        case .vPay:
            if #available(iOS 12.0, *) {
                return .vPay
            } else {
                fatalError()
            }
        case .barcode:
            if #available(iOS 14.0, *) {
                return .barcode
            } else {
                fatalError()
            }
        case .girocard:
            if #available(iOS 14.0, *) {
                return .girocard
            } else {
                fatalError()
            }
        }
    }
    
}

#endif
