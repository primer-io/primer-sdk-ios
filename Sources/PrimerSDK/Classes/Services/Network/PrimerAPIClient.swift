//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

let defaultNetworkService = DefaultNetworkService(
    requestFactory: DefaultNetworkRequestFactory(),
    requestDispatcher: DefaultRequestDispatcher(),
    reportingService: DefaultNetworkReportingService()
)

class PrimerAPIClient: PrimerAPIClientProtocol {
    let networkService: NetworkService

    // MARK: - Object lifecycle

    init(networkService: NetworkService = defaultNetworkService) {
        self.networkService = networkService
    }

    func genericAPICall(clientToken: DecodedJWTToken, url: URL, completion: @escaping APICompletion<Bool>) {
        let endpoint = PrimerAPI.redirect(clientToken: clientToken, url: url)
        networkService.request(endpoint) { (result: Result<SuccessResponse, Error>) in
            switch result {
            case .success:
                completion(.success(true))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func genericAPICall(clientToken: DecodedJWTToken, url: URL) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            self.genericAPICall(clientToken: clientToken, url: url) { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchVaultedPaymentMethods(
        clientToken: DecodedJWTToken,
        completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>
    ) {
        let endpoint = PrimerAPI.fetchVaultedPaymentMethods(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<Response.Body.VaultedPaymentMethods, Error>) in
            switch result {
            case let .success(vaultedPaymentMethodsResponse):
                AppState.current.selectedPaymentMethodId = vaultedPaymentMethodsResponse.data.first?.id
                completion(.success(vaultedPaymentMethodsResponse))
            case let .failure(err):
                completion(.failure(err))
            }
        }
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) async throws -> Response.Body.VaultedPaymentMethods {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchVaultedPaymentMethods(clientToken: clientToken) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func exchangePaymentMethodToken(
        clientToken: DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?,
        completion: @escaping APICompletion<PrimerPaymentMethodTokenData>
    ) {
        let endpoint = PrimerAPI.exchangePaymentMethodToken(clientToken: clientToken,
                                                            vaultedPaymentMethodId: vaultedPaymentMethodId,
                                                            vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData)
        execute(endpoint, completion: completion)
    }

    func exchangePaymentMethodToken(
        clientToken: DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PrimerPaymentMethodTokenData {
        return try await withCheckedThrowingContinuation { continuation in
            self.exchangePaymentMethodToken(clientToken: clientToken,
                                            vaultedPaymentMethodId: vaultedPaymentMethodId,
                                            vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String, completion: @escaping APICompletion<Void>) {
        let endpoint = PrimerAPI.deleteVaultedPaymentMethod(clientToken: clientToken, id: id)
        networkService.request(endpoint) { (result: Result<DummySuccess, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case let .failure(error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error))
            }
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchConfiguration(clientToken: DecodedJWTToken,
                            requestParameters: Request.URLParameters.Configuration?,
                            completion: @escaping ConfigurationCompletion) {
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters)
        let retryConfig = RetryConfig(enabled: true)
        networkService.request(endpoint, retryConfig: retryConfig) { (result: Result<PrimerAPIConfiguration, Error>, headers) in
            switch result {
            case let .success(result):
                completion(.success(result), headers)
            case let .failure(error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error), nil)
            }
        }
    }

    func fetchConfiguration(clientToken: DecodedJWTToken,
                            requestParameters: Request.URLParameters.Configuration?) async throws -> (PrimerAPIConfiguration, [String: String]?) {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters) { result, headers in
                switch result {
                case let .success(response):
                    continuation.resume(returning: (response, headers))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func createPayPalOrderSession(clientToken: DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>) {
        let endpoint = PrimerAPI.createPayPalOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        execute(endpoint, completion: completion)
    }

    func createPayPalOrderSession(clientToken: DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder) async throws -> Response.Body.PayPal.CreateOrder {
        return try await withCheckedThrowingContinuation { continuation in
            self.createPayPalOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
                                             completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>) {
        let endpoint = PrimerAPI.createPayPalBillingAgreementSession(clientToken: clientToken,
                                                                     payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        execute(endpoint, completion: completion)
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement) async throws -> Response
        .Body.PayPal.CreateBillingAgreement {
        return try await withCheckedThrowingContinuation { continuation in
            self.createPayPalBillingAgreementSession(
                clientToken: clientToken,
                payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest
            ) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
                                       completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>) {
        let endpoint = PrimerAPI.confirmPayPalBillingAgreement(clientToken: clientToken,
                                                               payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        execute(endpoint, completion: completion)
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement) async throws -> Response
        .Body.PayPal.ConfirmBillingAgreement {
        return try await withCheckedThrowingContinuation { continuation in
            self
                .confirmPayPalBillingAgreement(clientToken: clientToken,
                                               payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest) { result in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: response)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping APICompletion<Response.Body.Klarna.PaymentSession>
    ) {
        let endpoint = PrimerAPI.createKlarnaPaymentSession(clientToken: clientToken,
                                                            klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
        execute(endpoint, completion: completion)
    }

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession
    ) async throws -> Response.Body.Klarna.PaymentSession {
        return try await withCheckedThrowingContinuation { continuation in
            self
                .createKlarnaPaymentSession(clientToken: clientToken,
                                            klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest) { result in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: response)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func createKlarnaCustomerToken(clientToken: DecodedJWTToken,
                                   klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
                                   completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {
        let endpoint = PrimerAPI.createKlarnaCustomerToken(clientToken: clientToken,
                                                           klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest)
        execute(endpoint, completion: completion)
    }

    func createKlarnaCustomerToken(clientToken: DecodedJWTToken,
                                   klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken) async throws -> Response.Body.Klarna
        .CustomerToken {
        return try await withCheckedThrowingContinuation { continuation in
            self
                .createKlarnaCustomerToken(clientToken: clientToken,
                                           klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest) { result in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: response)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedJWTToken,
                                      klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
                                      completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {
        let endpoint = PrimerAPI.finalizeKlarnaPaymentSession(clientToken: clientToken,
                                                              klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        execute(endpoint, completion: completion)
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedJWTToken,
                                      klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession) async throws -> Response.Body
        .Klarna.CustomerToken {
        return try await withCheckedThrowingContinuation { continuation in
            self
                .finalizeKlarnaPaymentSession(clientToken: clientToken,
                                              klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest) { result in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: response)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping APICompletion<BanksListSessionResponse>
    ) {
        let endpoint = PrimerAPI.listAdyenBanks(clientToken: clientToken, request: request)
        execute(endpoint, completion: completion)
    }

    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList
    ) async throws -> BanksListSessionResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.listAdyenBanks(clientToken: clientToken, request: request) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func listRetailOutlets(clientToken: DecodedJWTToken,
                           paymentMethodId: String,
                           completion: @escaping APICompletion<RetailOutletsList>) {
        let endpoint = PrimerAPI.listRetailOutlets(clientToken: clientToken, paymentMethodId: paymentMethodId)
        execute(endpoint, completion: completion)
    }

    func listRetailOutlets(clientToken: DecodedJWTToken,
                           paymentMethodId: String) async throws -> RetailOutletsList {
        return try await withCheckedThrowingContinuation { continuation in
            self.listRetailOutlets(clientToken: clientToken, paymentMethodId: paymentMethodId) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func poll(clientToken: DecodedJWTToken?,
              url: String,
              completion: @escaping APICompletion<PollingResponse>) {
        let endpoint = PrimerAPI.poll(clientToken: clientToken, url: url)
        execute(endpoint, completion: completion)
    }

    func poll(clientToken: DecodedJWTToken?,
              url: String) async throws -> PollingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.poll(clientToken: clientToken, url: url) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken,
                                               request: ClientSessionUpdateRequest,
                                               completion: @escaping ConfigurationCompletion) {
        let endpoint = PrimerAPI.requestPrimerConfigurationWithActions(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<PrimerAPIConfiguration, Error>, headers) in
            switch result {
            case let .success(result):
                completion(.success(result), headers)
            case let .failure(error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error), nil)
            }
        }
    }

    func requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken,
                                               request: ClientSessionUpdateRequest) async throws -> (PrimerAPIConfiguration, [String: String]?) {
        return try await withCheckedThrowingContinuation { continuation in
            self.requestPrimerConfigurationWithActions(clientToken: clientToken, request: request) { result, headers in
                switch result {
                case let .success(response):
                    continuation.resume(returning: (response, headers))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL, body: [Analytics.Event]?,
                             completion: @escaping APICompletion<Analytics.Service.Response>) {
        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: clientToken, url: url, body: body)
        execute(endpoint, completion: completion)
    }

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL, body: [Analytics.Event]?) async throws -> Analytics.Service.Response {
        return try await withCheckedThrowingContinuation { continuation in
            self.sendAnalyticsEvents(clientToken: clientToken, url: url, body: body) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>) {
        let endpoint = PrimerAPI.fetchPayPalExternalPayerInfo(clientToken: clientToken,
                                                              payPalExternalPayerInfoRequestBody: payPalExternalPayerInfoRequestBody)
        execute(endpoint, completion: completion)
    }

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo) async throws -> Response.Body.PayPal
        .PayerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            self
                .fetchPayPalExternalPayerInfo(clientToken: clientToken,
                                              payPalExternalPayerInfoRequestBody: payPalExternalPayerInfoRequestBody) { result in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: response)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func validateClientToken(request: Request.Body.ClientTokenValidation,
                             completion: @escaping APICompletion<SuccessResponse>) {
        let endpoint = PrimerAPI.validateClientToken(request: request)
        execute(endpoint, completion: completion)
    }

    func validateClientToken(request: Request.Body.ClientTokenValidation) async throws -> SuccessResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.validateClientToken(request: request) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func createPayment(clientToken: DecodedJWTToken,
                       paymentRequestBody: Request.Body.Payment.Create,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
        let endpoint = PrimerAPI.createPayment(clientToken: clientToken, paymentRequest: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func createPayment(clientToken: DecodedJWTToken,
                       paymentRequestBody: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        return try await withCheckedThrowingContinuation { continuation in
            self.createPayment(clientToken: clientToken, paymentRequestBody: paymentRequestBody) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func resumePayment(clientToken: DecodedJWTToken,
                       paymentId: String,
                       paymentResumeRequest: Request.Body.Payment.Resume,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
        let endpoint = PrimerAPI.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest)
        execute(endpoint, completion: completion)
    }

    func resumePayment(clientToken: DecodedJWTToken,
                       paymentId: String,
                       paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        return try await withCheckedThrowingContinuation { continuation in
            self.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func completePayment(clientToken: DecodedJWTToken,
                         url: URL,
                         paymentRequest: Request.Body.Payment.Complete,
                         completion: @escaping APICompletion<Response.Body.Complete>) {
        let endpoint = PrimerAPI.completePayment(clientToken: clientToken, url: url, paymentRequest: paymentRequest)
        execute(endpoint, completion: completion)
    }

    func completePayment(clientToken: DecodedJWTToken,
                         url: URL,
                         paymentRequest: Request.Body.Payment.Complete) async throws -> Response.Body.Complete {
        return try await withCheckedThrowingContinuation { continuation in
            self.completePayment(clientToken: clientToken, url: url, paymentRequest: paymentRequest) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func testFinalizePolling(clientToken: DecodedJWTToken, testId: String, completion: @escaping APICompletion<Void>) {
        let endpoint = PrimerAPI.testFinalizePolling(clientToken: clientToken, testId: testId)
        networkService.request(endpoint) { (result: Result<Response.Body.Payment, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case let .failure(err):
                completion(.failure(err))
            }
        }
    }

    func testFinalizePolling(clientToken: DecodedJWTToken, testId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.testFinalizePolling(clientToken: clientToken, testId: testId) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func listCardNetworks(
        clientToken: DecodedJWTToken,
        bin: String,
        completion: @escaping APICompletion<Response.Body.Bin.Networks>
    ) -> PrimerCancellable? {
        let endpoint = PrimerAPI.listCardNetworks(clientToken: clientToken, bin: bin)
        return execute(endpoint, completion: completion)
    }

    func listCardNetworks(clientToken: DecodedJWTToken,
                          bin: String) async throws -> Response.Body.Bin.Networks {
        return try await withCheckedThrowingContinuation { continuation in
            self.listCardNetworks(clientToken: clientToken, bin: bin) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchNolSdkSecret(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
        completion: @escaping APICompletion<Response.Body.NolPay.NolPaySecretDataResponse>
    ) {
        let endpoint = PrimerAPI.getNolSdkSecret(clientToken: clientToken, request: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func fetchNolSdkSecret(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest
    ) async throws -> Response.Body.NolPay.NolPaySecretDataResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchNolSdkSecret(clientToken: clientToken, paymentRequestBody: paymentRequestBody) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
                          completion: @escaping APICompletion<Response.Body.PhoneMetadata.PhoneMetadataDataResponse>) {
        let endpoint = PrimerAPI.getPhoneMetadata(clientToken: clientToken,
                                                  request: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest) async throws -> Response.Body.PhoneMetadata
        .PhoneMetadataDataResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.getPhoneMetadata(clientToken: clientToken, paymentRequestBody: paymentRequestBody) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension PrimerAPIClient {
    @discardableResult
    private func execute<T>(_ endpoint: Endpoint, completion: @escaping APICompletion<T>) -> PrimerCancellable? where T: Decodable {
        networkService.request(endpoint) { (result: Result<T, Error>) in
            switch result {
            case let .success(result):
                completion(.success(result))
            case let .failure(error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error))
            }
        }
    }
}
