//
//  ExternalViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

import Foundation

#if canImport(UIKit)

internal protocol ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethod], Error>) -> Void)
}

internal class ExternalViewModel: ExternalViewModelProtocol {

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethod], Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.decodedClientToken.exists {
            let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
            vaultService.loadVaultedPaymentMethods({ err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    let paymentMethods = state.paymentMethods
                    completion(.success(paymentMethods))
                }
            })
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig({ err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                    vaultService.loadVaultedPaymentMethods({ err in
                        if let err = err {
                            completion(.failure(err))
                        } else {
                            let paymentMethods = state.paymentMethods
                            completion(.success(paymentMethods))
                        }
                    })
                }
            })
        }
    }
}

internal class MockExternalViewModel: ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethod], Error>) -> Void) {

    }
}

#endif
