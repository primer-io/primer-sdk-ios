//
//  ExternalViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

import Foundation

protocol ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void)
}

class ExternalViewModel: ExternalViewModelProtocol {
    
    let context: CheckoutContextProtocol
    
    init(context: CheckoutContextProtocol) {
        self.context = context
    }
    
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        if (context.state.decodedClientToken.exists) {
            context.serviceLocator.vaultService.loadVaultedPaymentMethods({ [weak self] error in
                if let error = error { completion(.failure(error)) }
                guard let paymentMethods = self?.context.state.paymentMethods else { return }
                completion(.success(paymentMethods))
            })
        } else {
            context.serviceLocator.clientTokenService.loadCheckoutConfig({ [weak self] error in
                if let error = error { completion(.failure(error)) }
                self?.context.serviceLocator.vaultService.loadVaultedPaymentMethods({ [weak self] error in
                    if let error = error { completion(.failure(error)) }
                    guard let paymentMethods = self?.context.state.paymentMethods else { return }
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
