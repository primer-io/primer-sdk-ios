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

