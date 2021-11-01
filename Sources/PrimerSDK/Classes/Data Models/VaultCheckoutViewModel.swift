//
//  VaultCheckoutViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/8/21.
//

#if canImport(UIKit)

import Foundation

internal protocol VaultCheckoutViewModelProtocol {
    var paymentMethods: [PaymentMethodToken]? { get }
    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] { get }
    var selectedPaymentMethodId: String? { get }
    var amountStringed: String? { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    func authorizePayment(_ completion: @escaping (Error?) -> Void)
}

internal class VaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    
    private var resumeHandler: ResumeHandlerProtocol!
    
    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] {
        return PrimerConfiguration.paymentMethodConfigViewModels
    }

    var amountStringed: String? {
        if Primer.shared.flow.internalSessionFlow.vaulted { return nil }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let amount = settings.amount else { return "" }
        guard let currency = settings.currency else { return "" }
        return amount.toCurrencyString(currency: currency)
    }

    var paymentMethods: [PaymentMethodToken]? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.paymentMethods
    }

    var selectedPaymentMethodId: String? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.selectedPaymentMethodId
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init() {
        resumeHandler = self
    }

    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        if ClientTokenService.decodedClientToken != nil {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = PaymentMethodConfigService()
            paymentMethodConfigService.fetchConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let vaultService: VaultServiceProtocol = VaultService()
                    vaultService.loadVaultedPaymentMethods(completion)
                }
            })
        } else {
            let clientTokenService: ClientTokenServiceProtocol = ClientTokenService()
            clientTokenService.fetchClientToken({ err in
                if let err = err {
                    completion(err)
                } else {
                    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = PaymentMethodConfigService()
                    paymentMethodConfigService.fetchConfig({ err in
                        if let err = err {
                            completion(err)
                        } else {
                            let vaultService: VaultServiceProtocol = VaultService()
                            vaultService.loadVaultedPaymentMethods(completion)
                        }
                    })
                }
            })
        }
    }

    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let selectedPaymentMethod = state.paymentMethods?.first(where: { paymentMethod in
            return paymentMethod.token == state.selectedPaymentMethodId
        }) else { return }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        settings.authorizePayment(selectedPaymentMethod, completion)
        settings.onTokenizeSuccess(selectedPaymentMethod, completion)
        Primer.shared.delegate?.onTokenizeSuccess?(selectedPaymentMethod, resumeHandler: self)
    }

}

extension VaultCheckoutViewModel: ResumeHandlerProtocol {
    func handle(error: Error) {
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let evc = ErrorViewController(message: error.localizedDescription)
                evc.view.translatesAutoresizingMaskIntoConstraints = false
                evc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: evc)
            }
        }
    }
    
    func handle(newClientToken clientToken: String) {
        try? ClientTokenService.storeClientToken(clientToken)
    }
    
    func handleSuccess() {
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let svc = SuccessViewController()
                svc.view.translatesAutoresizingMaskIntoConstraints = false
                svc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: svc)
            }
        }
    }
}

#endif

