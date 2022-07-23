//
//  VaultCheckoutViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/8/21.
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

    }

    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        if ClientTokenService.decodedClientToken != nil {
            let configurationService: PrimerAPIConfigurationServiceProtocol = PrimerAPIConfigurationService(requestDisplayMetadata: true)
            firstly {
                configurationService.fetchConfiguration()
            }
            .done {
                let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                vaultService.loadVaultedPaymentMethods(completion)
            }
            .catch { err in
                completion(err)
            }
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(err)
        }
    }

}

#endif
