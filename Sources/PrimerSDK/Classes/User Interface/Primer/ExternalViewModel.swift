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

internal protocol ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void)
}

internal class ExternalViewModel: ExternalViewModelProtocol {

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        if ClientTokenService.decodedClientToken.exists {
            let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
            vaultService.loadVaultedPaymentMethods({ err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    let paymentMethods = AppState.current.paymentMethods
                    completion(.success(paymentMethods))
                }
            })
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
        }
    }
}

internal class MockExternalViewModel: ExternalViewModelProtocol {
    func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {

    }
}

#endif
