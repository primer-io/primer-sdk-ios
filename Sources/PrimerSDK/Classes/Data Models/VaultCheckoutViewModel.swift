//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

internal protocol VaultCheckoutViewModelProtocol {
    var paymentMethods: [PaymentMethodToken] { get }
    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] { get }
    var selectedPaymentMethod: PaymentMethodToken? { get }
    var amountStringed: String? { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
}

internal class VaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    
    private var resumeHandler: ResumeHandlerProtocol!

    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] {
        return PrimerAPIConfiguration.paymentMethodConfigViewModels
    }

    var amountStringed: String? {
        if (Primer.shared.intent ?? .vault) == .vault { return nil }
        
        guard let amount = AppState.current.amount else { return nil }
        guard let currency = AppState.current.currency else { return nil }
        return amount.toCurrencyString(currency: currency)
    }

    var paymentMethods: [PaymentMethodToken] {
        if #available(iOS 11.0, *) {
            return AppState.current.paymentMethods
        } else {
            return AppState.current.paymentMethods.filter {
                switch $0.paymentInstrumentType {
                case .paymentCard: return true
                default: return false
                }
            }
        }
    }

    var selectedPaymentMethod: PaymentMethodToken? {
        return AppState.current.selectedPaymentMethod
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init() {
//        resumeHandler = self
    }

    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        if ClientTokenService.decodedClientToken != nil {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                    vaultService.loadVaultedPaymentMethods(completion)
                }
            })
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(err)
        }
    }

}

#endif
