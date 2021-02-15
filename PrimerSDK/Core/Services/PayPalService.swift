import Foundation

protocol PayPalServiceProtocol {
    func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
}

class PayPalService: PayPalServiceProtocol {
    
    @Dependency private(set) var api: APIClientProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    private func prepareUrlAndTokenAndId(path: String) -> (DecodedClientToken, URL, String)? {
        guard let clientToken = state.decodedClientToken else {
            return nil
        }
        
        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return nil
        }
        
        guard let coreURL = clientToken.coreUrl else {
            return nil
        }
        
        guard let url = URL(string: "\(coreURL)\(path)") else {
            return nil
        }
        
        return (clientToken, url, configId)
    }
    
    func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let tokenAndUrlAndId = prepareUrlAndTokenAndId(path: "/paypal/orders/create") else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let amount = state.settings.amount else {
            fatalError("Paypal checkout requires amount value!")
        }
        
        guard let currency = state.settings.currency else {
            fatalError("Paypal checkout requires currency value!")
        }
        
        guard let urlScheme = state.settings.urlScheme else {
            fatalError("Paypal checkout requires URL Scheme value!")
        }
        
        let body = PayPalCreateOrderRequest(
            paymentMethodConfigId: tokenAndUrlAndId.2,
            amount: amount,
            currencyCode: currency,
            returnUrl: urlScheme,
            cancelUrl: urlScheme
        )
        
        self.api.post(tokenAndUrlAndId.0, body: body, url: tokenAndUrlAndId.1, completion: { [weak self] result in
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
        guard let tokenAndUrlAndId = prepareUrlAndTokenAndId(path: "/paypal/billing-agreements/create-agreement") else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let urlScheme = state.settings.urlScheme else {
            fatalError("Paypal checkout requires URL Scheme value!")
        }
        
        
        let body = PayPalCreateBillingAgreementRequest(
            paymentMethodConfigId: tokenAndUrlAndId.2,
            returnUrl: urlScheme,
            cancelUrl: urlScheme
        )
        
        self.api.post(tokenAndUrlAndId.0, body: body, url: tokenAndUrlAndId.1, completion: { [weak self] result in
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
        guard let tokenId = state.billingAgreementToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        guard let tokenAndUrlAndId = prepareUrlAndTokenAndId(path: "/paypal/billing-agreements/confirm-agreement") else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }
        
        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: tokenAndUrlAndId.2, tokenId: tokenId)
        
        self.api.post(tokenAndUrlAndId.0, body: body, url: tokenAndUrlAndId.1, completion: { [weak self] result in
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
