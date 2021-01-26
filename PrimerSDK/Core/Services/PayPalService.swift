import Foundation

protocol PayPalServiceProtocol {
    func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
}

class PayPalService: PayPalServiceProtocol {
    
    private let api: APIClientProtocol
    private var state: AppStateProtocol
    
    init(api: APIClientProtocol, state: AppStateProtocol) {
        self.api = api
        self.state = state
    }
    
    func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let coreURL = clientToken.coreUrl else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let url = URL(string: "\(coreURL)/paypal/orders/create") else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        let body = PayPalCreateOrderRequest(
            paymentMethodConfigId: configId,
            amount: state.settings.amount,
            currencyCode: state.settings.currency,
            returnUrl: state.settings.urlScheme,
            cancelUrl: state.settings.urlScheme
        )
        
        self.api.post(clientToken, body: body, url: url, completion: { [weak self] result in
            switch result {
            case .failure: completion(.failure(PrimerError.PayPalSessionFailed))
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(PayPalCreateOrderResponse.self, from: data)
                    self?.state.orderId = response.orderId
                    completion(.success(response.approvalUrl))
                } catch {
                    completion(.failure(PrimerError.PayPalSessionFailed))
                }
            }
        })
    }
    
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        print("🚀 startBillingAgreementSession")
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        print("🚀 clientToken", clientToken)
        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        print("🚀 configId", configId)
        guard let coreURL = clientToken.coreUrl else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        print("🚀 coreURL", coreURL)
        guard let url = URL(string: "\(coreURL)/paypal/billing-agreements/create-agreement") else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        let body = PayPalCreateBillingAgreementRequest(
            paymentMethodConfigId: configId,
            returnUrl: state.settings.urlScheme,
            cancelUrl: state.settings.urlScheme
        )
        
        self.api.post(clientToken, body: body, url: url, completion: { [weak self] result in
            switch result {
            case .failure: completion(.failure(PrimerError.PayPalSessionFailed))
            case .success(let data):
                do {
                    let config = try JSONDecoder().decode(PayPalCreateBillingAgreementResponse.self, from: data)
                    self?.state.billingAgreementToken = config.tokenId
                    completion(.success(config.approvalUrl))
                } catch {
                    completion(.failure(PrimerError.PayPalSessionFailed))
                }
            }
        })
    }
    
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let coreURL = clientToken.coreUrl else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let tokenId = state.billingAgreementToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let url = URL(string: "\(coreURL)/paypal/billing-agreements/confirm-agreement") else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: configId, tokenId: tokenId)
        
        self.api.post(clientToken, body: body, url: url, completion: { [weak self] result in
            switch result {
            case .failure: completion(.failure(PrimerError.PayPalSessionFailed))
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(PayPalConfirmBillingAgreementResponse.self, from: data)
                    self?.state.confirmedBillingAgreement = response
                    completion(.success(response))
                } catch {
                    completion(.failure(PrimerError.PayPalSessionFailed))
                }
            }
        })
    }
}
