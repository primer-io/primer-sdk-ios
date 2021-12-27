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
            let err = PrimerInternalError.invalidClientToken
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .payPal) else {
            let err = PaymentError.invalidValue(key: "configuration.paypal.id", value: state.primerConfiguration?.getConfigId(for: .payPal))
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        guard let amount = settings.amount else {
            let err = PaymentError.invalidAmount(amount: settings.amount)
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let currency = settings.currency else {
            let err = PaymentError.invalidCurrency(currency: settings.currency?.rawValue)
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        guard var urlScheme = settings.urlScheme else {
            let err = PaymentError.invalidValue(key: "urlScheme", value: settings.urlScheme)
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
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
            case .failure(let err):
                let containerErr = PaymentError.failedToCreateSession(error: err)
                _ = ErrorHandler.shared.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let res):
                completion(.success(res))
            }
        }
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .payPal) else {
            let err = PaymentError.invalidValue(key: "configuration.paypal.id", value: state.primerConfiguration?.getConfigId(for: .payPal))
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        guard var urlScheme = settings.urlScheme else {
            let err = PaymentError.invalidValue(key: "urlScheme", value: settings.urlScheme)
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
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
            case .failure(let err):
                let containerErr = PaymentError.failedToCreateSession(error: err)
                _ = ErrorHandler.shared.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let config):
                self?.paypalTokenId = config.tokenId
                completion(.success(config.approvalUrl))
            }
        }
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .payPal) else {
            let err = PaymentError.invalidValue(key: "configuration.paypal.id", value: state.primerConfiguration?.getConfigId(for: .payPal))
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let tokenId = self.paypalTokenId else {
            let err = PaymentError.invalidValue(key: "paypalTokenId", value: self.paypalTokenId)
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }

        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: configId, tokenId: tokenId)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.payPalConfirmBillingAgreement(clientToken: decodedClientToken, payPalConfirmBillingAgreementRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PaymentError.failedToCreateSession(error: err)
                _ = ErrorHandler.shared.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let response):
                completion(.success(response))
            }
        }
    }

}

#endif
