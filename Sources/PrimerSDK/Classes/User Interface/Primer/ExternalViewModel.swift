//
//  ExternalViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

import Foundation

#if canImport(UIKit)

protocol ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void)
}

class ExternalViewModel: ExternalViewModelProtocol {

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.decodedClientToken.exists {
            let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
            vaultService.loadVaultedPaymentMethods({ [weak self] error in
                if let error = error { completion(.failure(error)) }
                let paymentMethods = state.paymentMethods
                completion(.success(paymentMethods))
            })
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig({ [weak self] error in
                if let error = error { completion(.failure(error)) }
                
                let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                vaultService.loadVaultedPaymentMethods({ [weak self] error in
                    if let error = error { completion(.failure(error)) }
                    let paymentMethods = state.paymentMethods
                    completion(.success(paymentMethods))
                })
            })
        }
    }
}

class MockExternalViewModel: ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {

    }
}

#endif
