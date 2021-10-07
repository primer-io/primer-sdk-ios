//
//  PaymentMethodViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

import Foundation

class PaymentMethodConfigViewModel {
    
    var config: ConfigPaymentMethod
    
    lazy var title: String = {
        switch config.type {
        case .applePay:
            return "Apple Pay"
        case .payPal:
            return "PayPal"
        case .paymentCard:
            return "Payment Card"
        case .googlePay:
            return "Google Pay"
        case .goCardlessMandate:
            return "Go Cardless"
        case .klarna:
            return "Klarna"
        case .payNlIdeal:
            return "Pay NL Ideal"
        case .apaya:
            return "Apaya"
        case .hoolah:
            return "Hoolah"
        case .unknown:
            return "Unknown"
        }
    }()
    
    lazy var buttonTitle: String? = {
        switch config.type {
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
        
        case .goCardlessMandate:
            return NSLocalizedString("payment-method-type-go-cardless",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Bank account",
                                     comment: "Bank account - Payment Method Type (Go Cardless)")
        
        case .payNlIdeal:
            return "Pay NL Ideal"
            
        case .apaya:
            return NSLocalizedString("payment-method-type-pay-by-mobile",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Pay by mobile",
                                     comment: "Pay by mobile - Payment By Mobile (Apaya)")
        case .hoolah:
            return "Hoolah"
        
        case .applePay:
            return nil
        case .googlePay:
            return nil
        case .klarna:
            return nil
        case .payPal:
            return nil
        case .unknown:
            return nil
        }
    }()
    
    lazy var buttonImage: UIImage? = {
        switch config.type {
        case .applePay:
            return UIImage(named: "appleIcon", in: Bundle.primerResources, compatibleWith: nil)
        case .payPal:
            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)
        case .googlePay:
            return nil
        case .goCardlessMandate:
            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)
        case .klarna:
            return UIImage(named: "klarna", in: Bundle.primerResources, compatibleWith: nil)
        case .payNlIdeal:
            return nil
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)
        case .hoolah:
            return nil
        case .unknown:
            return nil
        }
    }()
    
    init(config: ConfigPaymentMethod) {
        self.config = config
    }

    func tokenize(_ compleion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = state.decodedClientToken else { return }
        
        guard let configId = config.id else { return }
        
        let request = AsyncPaymentMethodTokenizationRequest(
            paymentMethodType: config.type,
            paymentMethodConfigId: configId)
        
        let client: PrimerAPIClient = DependencyContainer.resolve()
        client.tokenizePaymentMethod(
            clientToken: decodedClientToken,
            paymentMethodTokenizationRequest: request) { result in
                compleion(result)
            }
    }
    
}
