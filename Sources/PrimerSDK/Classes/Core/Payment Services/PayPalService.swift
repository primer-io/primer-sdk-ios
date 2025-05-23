// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation

internal protocol PayPalServiceProtocol {
    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void)
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void)
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void)
}

final class PayPalService: PayPalServiceProtocol {

    private var paypalTokenId: String?

    let apiClient: PrimerAPIClientPayPalProtocol

    init(apiClient: PrimerAPIClientPayPalProtocol = PrimerAPIClient()) {
        self.apiClient = apiClient
    }

    // swiftlint:disable:next large_tuple
    private func prepareUrlAndTokenAndId(path: String) -> (DecodedJWTToken, URL, String)? {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return nil
        }

        guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue)
        else {
            return nil
        }

        guard let coreURL = decodedJWTToken.coreUrl
        else {
            return nil
        }

        guard let url = URL(string: "\(coreURL)\(path)")
        else {
            return nil
        }

        return (decodedJWTToken, url, configId)
    }

    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        let apiConfig = PrimerAPIConfigurationModule.apiConfiguration
        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let amount = AppState.current.amount else {
            let err = PrimerError.invalidValue(
                key: "amount",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let currency = AppState.current.currency else {
            let err = PrimerError.invalidValue(
                key: "currency",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        var scheme: String
        do {
            scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        } catch let error {
            completion(.failure(error))
            return
        }

        let body = Request.Body.PayPal.CreateOrder(
            paymentMethodConfigId: configId,
            amount: amount,
            currencyCode: currency.code,
            returnUrl: "\(scheme)://paypal-success",
            cancelUrl: "\(scheme)://paypal-cancel"
        )

        apiClient.createPayPalOrderSession(clientToken: decodedJWTToken, payPalCreateOrderRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err,
                                                                     userInfo: .errorUserInfoDictionary(),
                                                                     diagnosticsId: UUID().uuidString)
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
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        var scheme: String
        do {
            scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        } catch let error {
            completion(.failure(error))
            return
        }

        let body = Request.Body.PayPal.CreateBillingAgreement(
            paymentMethodConfigId: configId,
            returnUrl: "\(scheme)://paypal-success",
            cancelUrl: "\(scheme)://paypal-cancel"
        )

        apiClient.createPayPalBillingAgreementSession(clientToken: decodedJWTToken,
                                                      payPalCreateBillingAgreementRequest: body) { [weak self] (result) in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err,
                                                                     userInfo: .errorUserInfoDictionary(),
                                                                     diagnosticsId: UUID().uuidString)
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
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let tokenId = self.paypalTokenId else {
            let err = PrimerError.invalidValue(
                key: "paypalTokenId",
                value: self.paypalTokenId,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        let body = Request.Body.PayPal.ConfirmBillingAgreement(paymentMethodConfigId: configId, tokenId: tokenId)

        apiClient.confirmPayPalBillingAgreement(clientToken: decodedJWTToken,
                                                payPalConfirmBillingAgreementRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err,
                                                                     userInfo: .errorUserInfoDictionary(),
                                                                     diagnosticsId: UUID().uuidString)
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
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            let err = PrimerError.invalidValue(
                key: "configuration.paypal.id",
                value: state.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue),
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

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
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
