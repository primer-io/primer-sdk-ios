#if canImport(UIKit)

import Foundation

internal protocol PayPalServiceProtocol {
    func startOrderSession(_ completion: @escaping (Result<PayPalCreateOrderResponse, Error>) -> Void)
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
}

internal class PayPalService: PayPalServiceProtocol {
    
    private var paypalTokenId: String?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    private func prepareUrlAndTokenAndId(path: String) -> (DecodedClientToken, URL, String)? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return nil
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .payPal) else {
            return nil
        }

        guard let coreURL = decodedClientToken.coreUrl else {
            return nil
        }

        guard let url = URL(string: "\(coreURL)\(path)") else {
            return nil
        }

        return (decodedClientToken, url, configId)
    }

    func startOrderSession(_ completion: @escaping (Result<PayPalCreateOrderResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(.failure(PrimerError.clientTokenNull))
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .payPal) else {
            return completion(.failure(PrimerError.configFetchFailed))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        guard let amount = settings.amount else {
            return completion(.failure(PrimerError.amountMissing))
        }

        guard let currency = settings.currency else {
            return completion(.failure(PrimerError.currencyMissing))
        }

        guard var urlScheme = settings.urlScheme else {
            return completion(.failure(PrimerError.missingURLScheme))
        }
        
        if urlScheme.suffix(3) == "://" {
            urlScheme = urlScheme.replacingOccurrences(of: "://", with: "")
        }

        let body = PayPalCreateOrderRequest(
            paymentMethodConfigId: configId,
            amount: amount,
            currencyCode: currency,
            returnUrl: "\(urlScheme)://paypal-success",
            cancelUrl: "\(urlScheme)://paypal-cancel"
        )
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.payPalStartOrderSession(clientToken: decodedClientToken, payPalCreateOrderRequest: body) { result in
            switch result {
            case .failure:
                completion(.failure(PrimerError.payPalSessionFailed))
            case .success(let res):
                completion(.success(res))
            }
        }
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .payPal) else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        guard var urlScheme = settings.urlScheme else {
            return completion(.failure(PrimerError.missingURLScheme))
        }
        
        if urlScheme.suffix(3) == "://" {
            urlScheme = urlScheme.replacingOccurrences(of: "://", with: "")
        }

        let body = PayPalCreateBillingAgreementRequest(
            paymentMethodConfigId: configId,
            returnUrl: "\(urlScheme)://paypal-success",
            cancelUrl: "\(urlScheme)://paypal-cancel"
        )
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.payPalStartBillingAgreementSession(clientToken: decodedClientToken, payPalCreateBillingAgreementRequest: body) { [weak self] (result) in
            switch result {
            case .failure:
                completion(.failure(PrimerError.payPalSessionFailed))
            case .success(let config):
                self?.paypalTokenId = config.tokenId
                completion(.success(config.approvalUrl))
            }
        }
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .payPal) else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        guard let tokenId = self.paypalTokenId else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: configId, tokenId: tokenId)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.payPalConfirmBillingAgreement(clientToken: decodedClientToken, payPalConfirmBillingAgreementRequest: body) { result in
            switch result {
            case .failure:
                completion(.failure(PrimerError.payPalSessionFailed))
            case .success(let response):
                completion(.success(response))
            }
        }
    }

}

#endif
