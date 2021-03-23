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
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var vaultService: VaultServiceProtocol
    @Dependency private(set) var clientTokenService: ClientTokenServiceProtocol
    
    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }

    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        if (state.decodedClientToken.exists) {
            vaultService.loadVaultedPaymentMethods({ [weak self] error in
                if let error = error { completion(.failure(error)) }
                guard let paymentMethods = self?.state.paymentMethods else { return }
                completion(.success(paymentMethods))
            })
        } else {
            clientTokenService.loadCheckoutConfig({ [weak self] error in
                if let error = error { completion(.failure(error)) }
                self?.vaultService.loadVaultedPaymentMethods({ [weak self] error in
                    if let error = error { completion(.failure(error)) }
                    guard let paymentMethods = self?.state.paymentMethods else { return }
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
