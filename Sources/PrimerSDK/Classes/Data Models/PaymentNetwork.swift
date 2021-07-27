//
//  PaymentNetwork.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/4/21.
//

#if canImport(UIKit)

import Foundation
import PassKit

internal enum CardNetwork: String {
    case amex
    case chinaUnionPay
    case dankort
    case diners
    case discover
    case electron
    case elo
    case enroute
    case hiper
    case interac
    case jcb
    case maestro
    case masterCard
    case mir
    case visa
    case unknown
    
//    "AMEX"
//      | "DANKORT"
//      | "DINERS_CLUB"
//      | "DISCOVER"
//      | "ENROUTE"
//      | "ELO"
//      | "HIPER"
//      | "INTERAC"
//      | "JCB"
//      | "MAESTRO"
//      | "MASTERCARD"
//      | "MIR"
//      | "PRIVATE_LABEL"
//      | "UNIONPAY"
//      | "VISA"
//      | "OTHER";
    
    init(rawValue: String?) {
        switch rawValue?.lowercased() {
        case "amex":
            self = .amex
        case "unionpay":
            self = .chinaUnionPay
        case "diners_club":
            self = .diners
        case "dankort":
            self = .dankort
        case "discover":
            self = .discover
        case "electron":
            self = .electron
        case "enroute":
            self = .enroute
        case "elo":
            self = .elo
        case "hiper":
            self = .hiper
        case "interac":
            self = .interac
        case "jcb":
            self = .jcb
        case "maestro":
            self = .maestro
        case "mastercard":
            self = .masterCard
        case "mir":
            self = .mir
        case "visa":
            self = .visa
        default:
            self = .unknown
        }
    }
    
    var directoryServerId: String? {
        switch self {
        case .visa:
            return "A000000003"
        case .masterCard:
            return "A000000004"
        case .amex:
            return "A000000025"
        case .jcb:
            return "A000000065"
        case .diners:
            return "A000000152"
        case .chinaUnionPay:
            return "A000000333"
        default:
            return nil
        }
    }
}

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
    
    static var iOSSupportedPKPaymentNetworks: [PKPaymentNetwork] {
        var supportedNetworks: [PKPaymentNetwork] = [
            .amex,
            .chinaUnionPay,
            .discover,
            .interac,
            .masterCard,
            .privateLabel,
            .visa
        ]
        
        if #available(iOS 11.2, *) {
//            @available(iOS 11.2, *)
            supportedNetworks.append(.cartesBancaires)
        } else if #available(iOS 11.0, *) {
//            @available(iOS, introduced: 11.0, deprecated: 11.2, message: "Use PKPaymentNetworkCartesBancaires instead.")
            supportedNetworks.append(.carteBancaires)
        } else if #available(iOS 10.3, *) {
//            @available(iOS, introduced: 10.3, deprecated: 11.0, message: "Use PKPaymentNetworkCartesBancaires instead.")
            supportedNetworks.append(.carteBancaire)
        }

        if #available(iOS 12.0, *) {
//            @available(iOS 12.0, *)
            supportedNetworks.append(.eftpos)
            supportedNetworks.append(.electron)
            supportedNetworks.append(.maestro)
            supportedNetworks.append(.vPay)
        }

        if #available(iOS 12.1.1, *) {
//            @available(iOS 12.1.1, *)
            supportedNetworks.append(.elo)
            supportedNetworks.append(.mada)
        }
        
        if #available(iOS 10.3.1, *) {
//            @available(iOS 10.3, *)
            supportedNetworks.append(.idCredit)
        }
        
        if #available(iOS 10.1, *) {
//            @available(iOS 10.1, *)
            supportedNetworks.append(.JCB)
            supportedNetworks.append(.suica)
        }
        
        if #available(iOS 10.3, *) {
//            @available(iOS 10.3, *)
            supportedNetworks.append(.quicPay)
        }
        
        if #available(iOS 14.0, *) {
//            @available(iOS 14.0, *)
//            supportedNetworks.append(.barcode)
            supportedNetworks.append(.girocard)
        }
        
        return supportedNetworks
    }
    
}

#endif
