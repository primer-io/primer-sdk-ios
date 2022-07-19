#if canImport(UIKit)

import Foundation

internal protocol PayPalServiceProtocol {
    func startOrderSession(_ completion: @escaping (Result<PayPalCreateOrderResponse, Error>) -> Void)
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<PayPal.PayerInfo.Response, Error>) -> Void)
}

internal class PayPalService: PayPalServiceProtocol {
    
    private var paypalTokenId: String?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    private func prepareUrlAndTokenAndId(path: String) -> (DecodedClientToken, URL, String)? {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return nil
        }

        guard let configId = AppState.current.apiConfiguration?.getConfigId(for: "PAYPAL") else {
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
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = AppState.current.apiConfiguration?.getConfigId(for: "PAYPAL") else {
            let err = PrimerError.invalidValue(key: "configuration.paypal.id", value: AppState.current.apiConfiguration?.getConfigId(for: "PAYPAL"), userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let amount = AppState.current.amount else {
            let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let currency = AppState.current.currency else {
            let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard var urlScheme = PrimerSettings.current.paymentMethodOptions.urlScheme else {
            let err = PrimerError.invalidValue(key: "urlScheme", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
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

        api.createPayPalOrderSession(clientToken: decodedClientToken, payPalCreateOrderRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let res):
                completion(.success(res))
            }
        }
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: "PAYPAL") else {
            let err = PrimerError.invalidValue(key: "configuration.paypal.id", value: state.apiConfiguration?.getConfigId(for: "PAYPAL"), userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard var urlScheme = PrimerSettings.current.paymentMethodOptions.urlScheme else {
            let err = PrimerError.invalidValue(key: "urlScheme", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
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

        api.createPayPalBillingAgreementSession(clientToken: decodedClientToken, payPalCreateBillingAgreementRequest: body) { [weak self] (result) in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let config):
                self?.paypalTokenId = config.tokenId
                completion(.success(config.approvalUrl))
            }
        }
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: "PAYPAL") else {
            let err = PrimerError.invalidValue(key: "configuration.paypal.id", value: state.apiConfiguration?.getConfigId(for: "PAYPAL"), userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let tokenId = self.paypalTokenId else {
            let err = PrimerError.invalidValue(key: "paypalTokenId", value: self.paypalTokenId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: configId, tokenId: tokenId)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.confirmPayPalBillingAgreement(clientToken: decodedClientToken, payPalConfirmBillingAgreementRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let response):
                completion(.success(response))
            }
        }
    }
    
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<PayPal.PayerInfo.Response, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let configId = state.apiConfiguration?.getConfigId(for: "PAYPAL") else {
            let err = PrimerError.invalidValue(key: "configuration.paypal.id", value: state.apiConfiguration?.getConfigId(for: "PAYPAL"), userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.fetchPayPalExternalPayerInfo(
            clientToken: decodedClientToken,
            payPalExternalPayerInfoRequestBody: PayPal.PayerInfo.Request(paymentMethodConfigId: configId, orderId: orderId)) { result in
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let err):
                    completion(.failure(err))
                }
        }
    }
}

#endif
