//
//  KlarnaService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 22/02/2021.
//

enum KlarnaException: Error {
    case invalidUrl
    case noToken
    case noCoreUrl
    case failedApiCall
    case noAmount
    case noCurrency
    case noPaymentMethodConfigId
}

struct KlarnaCreatePaymentSessionAPIRequest: Codable {
    let paymentMethodConfigId: String
    let amount: Int
    let currencyCode: String
}

struct KlarnaCreatePaymentSessionAPIResponse: Codable {
    let sessionId: String
    let redirectUrl: String
}

protocol KlarnaServiceProtocol {
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void)
}


class KlarnaService: KlarnaServiceProtocol {
    
    @Dependency private(set) var api: APIClientProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let token = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }
        
        guard let coreUrl = token.coreUrl else {
            return completion(.failure(KlarnaException.noCoreUrl))
        }
        
        guard let url = URL(string: "\(coreUrl)/klarna/payment-sessions/create") else {
            return completion(.failure(KlarnaException.invalidUrl))
        }
        
        guard let amount = state.settings.amount else {
            return completion(.failure(KlarnaException.noAmount))
        }
        
        log(logLevel: .info, message: "amount: \(amount)")
        
        guard let currency = state.settings.currency else {
            return completion(.failure(KlarnaException.noCurrency))
        }
        
        guard let configId = state.paymentMethodConfig?.getConfigId(for: .KLARNA) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        let body = KlarnaCreatePaymentSessionAPIRequest(
            paymentMethodConfigId: configId,
            amount: amount,
            currencyCode: currency.rawValue
        )
        
        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "createPaymentSession", line: 66)
        
        // call backend
        self.api.post(token, body: body, url: url, completion: { result in
            switch result {
            case .failure: completion(.failure(KlarnaException.failedApiCall))
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(KlarnaCreatePaymentSessionAPIResponse.self, from: data)
                    log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession", line: 80)
                    completion(.success(response.redirectUrl))
                } catch {
                    completion(.failure(KlarnaException.failedApiCall))
                }
            }
        })
    }
    
}
