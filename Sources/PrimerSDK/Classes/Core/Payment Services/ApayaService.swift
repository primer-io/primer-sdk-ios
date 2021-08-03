//
//  ApayaService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 26/07/2021.
//

#if canImport(UIKit)

internal protocol ApayaServiceProtocol {
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void)
}

internal class ApayaService: ApayaServiceProtocol {
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(ApayaException.noToken))
        }
        let body = Apaya.CreateSessionAPIRequest(locale: "en-GB", itemDescription: "nothing")
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.apayaCreateSession(clientToken: clientToken, request: body) { result in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(
                    logLevel: .info,
                    message: "\(response)",
                    className: "ApayaService",
                    function: "createPaymentSession"
                )
                completion(.success(response.redirectUrl))
            }
        }
    }
}
#endif
