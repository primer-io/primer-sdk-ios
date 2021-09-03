//
//  ApayaService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 26/07/2021.
//

#if canImport(UIKit)

protocol OAuthServiceProtocol {
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void)
}

internal protocol ApayaServiceProtocol: OAuthServiceProtocol {}

internal class ApayaService: ApayaServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let clientToken = state.decodedClientToken,
              let merchantId = state.paymentMethodConfig?.getConfigId(for: .apaya),
              let accountId = state.paymentMethodConfig?.getProductId(for: .apaya)
        else {
            return completion(.failure(ApayaException.noToken))
        }
        let body = Apaya.CreateSessionAPIRequest(merchantAccountId: "a1070c8a-40a6-5a92-a6ea-c39e7538bb2d")
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.apayaCreateSession(clientToken: clientToken, request: body) { [weak self] result in
            switch result {
            case .failure(let error):
                Primer.shared.delegate?.checkoutFailed?(with: error)
                completion(.failure(ApayaException.failedToCreateSession))
            case .success(let response):
                log(
                    logLevel: .info,
                    message: "\(response)",
                    className: "\(String(describing: self.self))",
                    function: #function
                )

                completion(.success(response.url))
            }
        }
    }
    
}
#endif
