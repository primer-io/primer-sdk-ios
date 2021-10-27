//
//  PaymentMethodViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 14/10/21.
//



//import Foundation
//
//struct PaymentMethodViewModel {
//    
//    let type: ConfigPaymentMethodType
//    
//    var buttonTitle: String? {
//        switch type {
//        case .paymentCard:
//            return Primer.shared.flow.internalSessionFlow.vaulted
//                ? NSLocalizedString("payment-method-type-card-vaulted",
//                                    tableName: nil,
//                                    bundle: Bundle.primerResources,
//                                    value: "Add new card",
//                                    comment: "Add new card - Payment Method Type (Card Vaulted)")
//
//                : NSLocalizedString("payment-method-type-card-not-vaulted",
//                                    tableName: nil,
//                                    bundle: Bundle.primerResources,
//                                    value: "Pay with card",
//                                    comment: "Pay with card - Payment Method Type (Card Not vaulted)")
//
//        case .applePay:
//            return NSLocalizedString("payment-method-type-apple-pay",
//                                     tableName: nil,
//                                     bundle: Bundle.primerResources,
//                                     value: "Pay",
//                                     comment: "Pay - Payment Method Type (Apple pay)")
//
//        case .goCardlessMandate:
//            return NSLocalizedString("payment-method-type-go-cardless",
//                                     tableName: nil,
//                                     bundle: Bundle.primerResources,
//                                     value: "Bank account",
//                                     comment: "Bank account - Payment Method Type (Go Cardless)")
//
//        case .payPal:
//            break
//            
//        case .klarna:
//            break
//
//        case .apaya:
//            return "Pay by mobile"
//
//        default:
//            break
//        }
//        
//        return nil
//    }
//    
//    var buttonImage: UIImage? {
//        switch type {
//        case .applePay:
//            return UIImage(named: "appleIcon", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
//            
//        case .apaya:
//            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
//            
//        case .goCardlessMandate:
//            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
//            
//        case .googlePay:
//            break
//            
//        case .klarna:
//            return UIImage(named: "klarna", in: Bundle.primerResources, compatibleWith: nil)
//            
//        case .payNlIdeal:
//            break
//            
//        case .payPal:
//            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
//            
//        case .paymentCard:
//            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
//
//        case .unknown:
//            break
//        }
//        
//        return nil
//    }
//    
//    var logo: UIImage? {
//        switch type {
//        case .applePay:
//            return UIImage(named: "appleIcon", in: Bundle.primerResources, compatibleWith: nil)
//        case .apaya:
//            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)
//            
//        case .goCardlessMandate:
//            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)
//            
//        case .googlePay:
//            break
//            
//        case .klarna:
//            return UIImage(named: "klarna", in: Bundle.primerResources, compatibleWith: nil)
//            
//        case .payNlIdeal:
//            break
//            
//        case .payPal:
//            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
//            
//        case .paymentCard:
//            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)
//
//        case .unknown:
//            break
//        }
//        
//        return nil
//    }
//    
//    var surCharge: String? {
//        switch type {
//        case .paymentCard:
//            return NSLocalizedString("surcharge-additional-fee",
//                                     tableName: nil,
//                                     bundle: Bundle.primerResources,
//                                     value: "Additional fee may apply",
//                                     comment: "Additional fee may apply - Surcharge (Label)")
//        default:
//            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//            guard let currency = settings.currency else { return nil }
//
//            let state: AppStateProtocol = DependencyContainer.resolve()
//            guard let availablePaymentMethods = state.paymentMethodConfig?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
//
//            return availablePaymentMethods.filter({ $0.type == type }).first?.surcharge?.toCurrencyString(currency: currency)
//        }
//    }
//}

