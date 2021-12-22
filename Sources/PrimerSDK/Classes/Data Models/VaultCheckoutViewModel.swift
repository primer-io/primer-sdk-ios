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
    func authorizePayment(_ completion: @escaping (Error?) -> Void)
}

internal class VaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    
    private var resumeHandler: ResumeHandlerProtocol!

    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] {
        return PrimerConfiguration.paymentMethodConfigViewModels
    }

    var amountStringed: String? {
        if Primer.shared.flow == nil { return nil }
        if Primer.shared.flow.internalSessionFlow.vaulted { return nil }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let amount = settings.amount else { return nil }
        guard let currency = settings.currency else { return nil }
        return amount.toCurrencyString(currency: currency)
    }

    var paymentMethods: [PaymentMethodToken] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if #available(iOS 11.0, *) {
            return state.paymentMethods
        } else {
            return state.paymentMethods.filter {
                switch $0.paymentInstrumentType {
                case .goCardlessMandate: return true
                case .paymentCard: return true
                default: return false
                }
            }
        }
    }

    var selectedPaymentMethod: PaymentMethodToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.selectedPaymentMethod
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init() {
        resumeHandler = self
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
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.fetchClientToken({ err in
                if let err = err {
                    completion(err)
                } else {
                    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    paymentMethodConfigService.fetchConfig({ err in
                        if let err = err {
                            completion(err)
                        } else {
                            let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                            vaultService.loadVaultedPaymentMethods(completion)
                        }
                    })
                }
            })
        }
    }

    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let selectedPaymentMethod = state.selectedPaymentMethod else {
            completion(PrimerError.invalidValue(key: "selectedPaymentMethod"))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let sdkEvent1 = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "delegate": "authorizePayment(_:completion:)",
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ]))
        settings.authorizePayment(selectedPaymentMethod, completion)
        
        let sdkEvent2 = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "delegate": "onTokenizeSuccess(_:completion:)",
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ]))
        settings.onTokenizeSuccess(selectedPaymentMethod, completion)
        
        let sdkEvent3 = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "delegate": "onTokenizeSuccess(_:resumeHandler:)",
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ]))
        
        let sdkEvent4 = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "delegate": "onTokenizeSuccess(_:resumeHandler:)",
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)",
                ]))

        Analytics.Service.record(events: [sdkEvent1, sdkEvent2, sdkEvent3, sdkEvent4])
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

