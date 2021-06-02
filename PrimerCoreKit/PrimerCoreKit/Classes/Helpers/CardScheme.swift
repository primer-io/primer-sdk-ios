//
//  CardScheme.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 26/5/21.
//

import Foundation

public enum CardScheme: String {
    case amex, diners, discover, jcb, maestro, masterCard, visa, unknown, invalid, bancontact

    var fastIdRegex : String {
        switch self {
        case .amex:
            return "^3[47]"
        case .diners:
            return "^3[0689]"
        case .discover:
            return "^(60|64|65|622)"
        case .jcb:
            return "^(2131|1800|35[0-9]{3})"
        case .maestro:
            return "^(5018|502|503|506|56|58|639|6220|67)"
        case .masterCard:
            return "^(51|52|53|54|55|22|23|24|25|26|27)"
        case .visa:
            return "^4"
        default:
            return ""
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .masterCard:
            return UIImage(named: "mastercard", in: Bundle.primerCoreKitResources, compatibleWith: nil)
        case .visa:
            return UIImage(named: "visa", in: Bundle.primerCoreKitResources, compatibleWith: nil)
        default:
            return UIImage(named: "generic-card", in: Bundle.primerCoreKitResources, compatibleWith: nil)
        }
    }
    
    init(account: String) {
        let str = account.withoutWhiteSpace
        print("Account: \(str)")
        if str.withoutWhiteSpace.range(of: CardScheme.masterCard.fastIdRegex, options: .regularExpression, range: nil, locale: nil) != nil {
            self = .masterCard
        } else if str.withoutWhiteSpace.range(of: CardScheme.visa.fastIdRegex, options: .regularExpression, range: nil, locale: nil) != nil {
            self = .visa
        } else if str.withoutWhiteSpace.range(of: CardScheme.maestro.fastIdRegex, options: .regularExpression, range: nil, locale: nil) != nil {
            self = .maestro
        } else if str.withoutWhiteSpace.range(of: CardScheme.amex.fastIdRegex, options: .regularExpression, range: nil, locale: nil) != nil {
            self = .amex
        } else if str.withoutWhiteSpace.range(of: CardScheme.diners.fastIdRegex, options: .regularExpression, range: nil, locale: nil) != nil {
            self = .diners
        } else if str.withoutWhiteSpace.range(of: CardScheme.discover.fastIdRegex, options: .regularExpression, range: nil, locale: nil) != nil {
            self = .discover
        } else if str.withoutWhiteSpace.range(of: CardScheme.jcb.fastIdRegex, options: .regularExpression, range: nil, locale: nil) != nil {
            self = .jcb
        } else {
            self = .unknown
        }
    }
    
}
