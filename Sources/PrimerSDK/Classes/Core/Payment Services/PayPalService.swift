import Foundation

internal protocol PayPalServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol? { get set }
    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void)
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void)
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void)
}

internal class PayPalService: PayPalServiceProtocol {

    static var apiClient: PrimerAPIClientProtocol?

    private var paypalTokenId: String?

    private func prepareUrlAndTokenAndId(path: String) -> (DecodedJWTToken, URL, String)? {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return nil
        }

        guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            return nil
        }

        guard let coreURL = decodedJWTToken.coreUrl else {
            return nil
        }

        guard let url = URL(string: "\(coreURL)\(path)") else {
            return nil
        }

        return (decodedJWTToken, url, configId)
    }

    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let amount = AppState.current.amount else {
            let err = PrimerError.invalidSetting(
                name: "amount",
                value: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let currency = AppState.current.currency else {
            let err = PrimerError.invalidSetting(
                name: "currency",
                value: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard var urlScheme = PrimerSettings.current.paymentMethodOptions.urlScheme else {
            let err = PrimerError.invalidValue(
                key: "urlScheme",
                value: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        if urlScheme.suffix(3) == "://" {
            urlScheme = urlScheme.replacingOccurrences(of: "://", with: "")
        }

        let body = Request.Body.PayPal.CreateOrder(
            paymentMethodConfigId: configId,
            amount: amount,
			currencyCode: currency.code,
            returnUrl: "\(urlScheme)://paypal-success",
            cancelUrl: "\(urlScheme)://paypal-cancel"
        )

        let apiClient: PrimerAPIClientProtocol = PayPalService.apiClient ?? PrimerAPIClient()
        apiClient.createPayPalOrderSession(clientToken: decodedJWTToken, payPalCreateOrderRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file,
                                                                                            "class": "\(Self.self)",
                                                                                            "function": #function,
                                                                                            "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let res):
                completion(.success(res))
            }
        }
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard var urlScheme = PrimerSettings.current.paymentMethodOptions.urlScheme else {
            let err = PrimerError.invalidValue(
                key: "urlScheme",
                value: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        if urlScheme.suffix(3) == "://" {
            urlScheme = urlScheme.replacingOccurrences(of: "://", with: "")
        }

        let body = Request.Body.PayPal.CreateBillingAgreement(
            paymentMethodConfigId: configId,
            returnUrl: "\(urlScheme)://paypal-success",
            cancelUrl: "\(urlScheme)://paypal-cancel"
        )

        let apiClient: PrimerAPIClientProtocol = PayPalService.apiClient ?? PrimerAPIClient()
        apiClient.createPayPalBillingAgreementSession(clientToken: decodedJWTToken, payPalCreateBillingAgreementRequest: body) { [weak self] (result) in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file,
                                                                                            "class": "\(Self.self)",
                                                                                            "function": #function,
                                                                                            "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let config):
                self?.paypalTokenId = config.tokenId
                completion(.success(config.approvalUrl))
            }
        }
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let tokenId = self.paypalTokenId else {
            let err = PrimerError.invalidValue(
                key: "paypalTokenId",
                value: self.paypalTokenId,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        let body = Request.Body.PayPal.ConfirmBillingAgreement(paymentMethodConfigId: configId, tokenId: tokenId)

        let apiClient: PrimerAPIClientProtocol = PayPalService.apiClient ?? PrimerAPIClient()
        apiClient.confirmPayPalBillingAgreement(clientToken: decodedJWTToken, payPalConfirmBillingAgreementRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file,
                                                                                            "class": "\(Self.self)",
                                                                                            "function": #function,
                                                                                            "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: containerErr)
                completion(.failure(containerErr))
            case .success(let response):
                completion(.success(response))
            }
        }
    }

    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        let apiClient: PrimerAPIClientProtocol = PayPalService.apiClient ?? PrimerAPIClient()
        apiClient.fetchPayPalExternalPayerInfo(
            clientToken: decodedJWTToken,
            payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo(paymentMethodConfigId: configId, orderId: orderId)) { result in
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
    }
}
