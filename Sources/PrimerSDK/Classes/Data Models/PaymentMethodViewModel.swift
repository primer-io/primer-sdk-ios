//
//  PaymentMethodViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

import Foundation

struct PaymentMethodViewModel {
    func toString() -> String {
        log(logLevel: .debug, title: nil, message: "Payment option: \(self.type)", prefix: "🦋", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        switch type {
        case .paymentCard:
            return Primer.shared.flow.internalSessionFlow.vaulted
                ? NSLocalizedString("payment-method-type-card-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerResources,
                                    value: "Add new card",
                                    comment: "Add new card - Payment Method Type (Card Vaulted)")

                : NSLocalizedString("payment-method-type-card-not-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerResources,
                                    value: "Pay with card",
                                    comment: "Pay with card - Payment Method Type (Card Not vaulted)")

        case .applePay:
            return NSLocalizedString("payment-method-type-apple-pay",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Pay",
                                     comment: "Pay - Payment Method Type (Apple pay)")

        case .goCardlessMandate:
            return NSLocalizedString("payment-method-type-go-cardless",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Bank account",
                                     comment: "Bank account - Payment Method Type (Go Cardless)")

        case .payPal:
            return ""
            
        case .klarna:
            return NSLocalizedString("payment-method-type-klarna",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Klarna.",
                                     comment: "Klarna - Payment Method Type (Klarna)")

        case .apaya:
            return "Pay by mobile"
            
        case .hoolah:
            return "Hoolah"

        default:
            return ""
        }
    }

    func toIconName() -> ImageName? {
        log(logLevel: .debug, title: nil, message: "Payment option: \(self.type)", prefix: "🦋", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        switch type {
        case .applePay: return .appleIcon
        case .payPal: return  .paypal3
        case .goCardlessMandate: return .rightArrow
        case .klarna: return .klarna
        case .paymentCard: return .creditCard
        case .apaya: return .mobile
        default: return nil
        }
    }

    let type: ConfigPaymentMethodType
    
}
