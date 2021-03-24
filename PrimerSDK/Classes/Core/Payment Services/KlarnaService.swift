//
//  KlarnaService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 22/02/2021.
//

protocol KlarnaServiceProtocol {
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func createKlarnaCustomerToken(_ completion: @escaping (Result<String, Error>) -> Void)
    func finalizePaymentSession(_ completion: @escaping (Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void)
}

class KlarnaService: KlarnaServiceProtocol {

    @Dependency private(set) var api: PrimerAPIClientProtocol
    @Dependency private(set) var state: AppStateProtocol

    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }

        guard let amount = state.settings.amount else {
            return completion(.failure(KlarnaException.noAmount))
        }

        log(logLevel: .info, message: "Klarna amount: \(amount)")

        guard state.settings.currency != nil else {
            return completion(.failure(KlarnaException.noCurrency))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .KLARNA) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let countryCode = self.state.settings.countryCode else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let currency = self.state.settings.currency else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = KlarnaCreatePaymentSessionAPIRequest(
            paymentMethodConfigId: configId,
            sessionType: "HOSTED_PAYMENT_PAGE",
            redirectUrl: "https://primer.io",
            totalAmount: amount,
            localeData: KlarnaLocaleData(
                countryCode: countryCode.rawValue,
                currencyCode: currency.rawValue,
                localeCode: countryCode.klarnaLocaleCode
            ),
            orderItems: self.state.settings.orderItems
        )

        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "createPaymentSession")

        api.klarnaCreatePaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession")
                self?.state.sessionId = response.sessionId
                completion(.success(response.hppRedirectUrl))
            }
        }
    }
    
    func createKlarnaCustomerToken(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .KLARNA) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let authorizationToken = self.state.authorizationToken else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let sessionId = self.state.sessionId else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let countryCode = self.state.settings.countryCode else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let currency = self.state.settings.currency else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = CreateKlarnaCustomerTokenAPIRequest(
            paymentMethodConfigId: configId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            description: "primer",
            localeData: KlarnaLocaleData(
                countryCode: countryCode.rawValue,
                currencyCode: currency.rawValue,
                localeCode: countryCode.klarnaLocaleCode
            )
        )
        
        api.klarnaCreateCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createCustomerToken")
                completion(.success(response.customerTokenId))
            }
        }
    }

    func finalizePaymentSession(_ completion: @escaping (Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .KLARNA) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        guard let sessionId = state.sessionId else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = KlarnaFinalizePaymentSessionRequest(paymentMethodConfigId: configId, sessionId: sessionId)

        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession")

        api.klarnaFinalizePaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession")
                completion(.success(response))
            }
        }
    }
}

