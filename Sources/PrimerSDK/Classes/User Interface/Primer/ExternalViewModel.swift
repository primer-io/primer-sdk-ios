//
//  ExternalViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

import Foundation

internal protocol ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PrimerPaymentMethodTokenData], Error>) -> Void)
}

internal class ExternalViewModel: ExternalViewModelProtocol {

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PrimerPaymentMethodTokenData], Error>) -> Void) {
        if ClientTokenService.decodedClientToken.exists {
            let vaultService: VaultServiceProtocol = VaultService()
            firstly {
                vaultService.fetchVaultedPaymentMethods()
            }
            .done {
                let paymentMethods = AppState.current.paymentMethods
                completion(.success(paymentMethods))
            }
            .catch { err in
                completion(.failure(err))
            }
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
        }
    }
}

internal class MockExternalViewModel: ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PrimerPaymentMethodTokenData], Error>) -> Void) {

    }
}

#endif
