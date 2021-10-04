//
//  DirerctCheckoutViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/8/21.
//

import Foundation

#if canImport(UIKit)

import Foundation

internal protocol DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel? { get }
    var paymentMethods: [PaymentMethodViewModel] { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

internal class DirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    
    private var amount: Int? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.amount
    }
    
    private var currency: Currency? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.currency
    }

    var amountViewModel: AmountViewModel? {
        guard let amount = amount, let currency = currency else {
            return nil
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        var model = AmountViewModel(amount: amount, currency: currency)
        
        model.disabled = settings.directDebitHasNoAmount
        
        return model
    }
    var paymentMethods: [PaymentMethodViewModel] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.viewModels
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.decodedClientToken.exists {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig(completion)
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    paymentMethodConfigService.fetchConfig(completion)
                }
            })
        }
    }
}

enum PaymentMethodIcon: String {
    case creditCard = "creditCard"
    case appleIcon = "appleIcon"
    case paypal = "paypal"
}

struct PaymentMethodViewModel {
    
    let type: ConfigPaymentMethodType
    
    var buttonTitle: String? {
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

        default:
            break
        }
        
        return nil
    }
    
    var buttonImage: UIImage? {
        switch type {
        case .applePay:
            return UIImage(named: "appleIcon", in: Bundle.primerResources, compatibleWith: nil)
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)
            
        case .goCardlessMandate:
            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)
            
        case .googlePay:
            break
            
        case .klarna:
            return UIImage(named: "klarna", in: Bundle.primerResources, compatibleWith: nil)
            
        case .payNlIdeal:
            break
            
        case .payPal:
            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
            
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)

        case .unknown:
            break
        }
        
        return nil
    }
    
    var logo: UIImage? {
        switch type {
        case .applePay:
            return UIImage(named: "appleIcon", in: Bundle.primerResources, compatibleWith: nil)
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)
            
        case .goCardlessMandate:
            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)
            
        case .googlePay:
            break
            
        case .klarna:
            return UIImage(named: "klarna", in: Bundle.primerResources, compatibleWith: nil)
            
        case .payNlIdeal:
            break
            
        case .payPal:
            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
            
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)

        case .unknown:
            break
        }
        
        return nil
    }

}

struct AmountViewModel {
    let amount: Int
    let currency: Currency

    var disabled = false

    var formattedAmount: String {
        return String(format: "%.2f", (Double(amount) / 100))
    }
    func toLocal() -> String {
        if disabled { return "" }
        switch currency {
        case .USD:
            return "$\(formattedAmount)"
        case .GBP:
            return "£\(formattedAmount)"
        case .EUR:
            return "€\(formattedAmount)"
        case .JPY:
            return "¥\(amount)"
        case .SEK:
            return "\(amount) SEK"
        case .NOK:
            return "$\(amount) NOK"
        case .DKK:
            return "$\(amount) DKK"
        default:
            return "\(amount)"
        }
    }
}

#endif

