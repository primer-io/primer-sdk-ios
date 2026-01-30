//
//  PrimerAPIClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation

let defaultNetworkService = DefaultNetworkService(
    requestFactory: DefaultNetworkRequestFactory(),
    requestDispatcher: DefaultRequestDispatcher(),
    reportingService: DefaultNetworkReportingService()
)

// swiftlint:disable:next type_body_length
final class PrimerAPIClient: PrimerAPIClientProtocol {

    let networkService: NetworkServiceProtocol

    // MARK: - Object lifecycle

    init(networkService: NetworkServiceProtocol = defaultNetworkService) {
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
        let _: SuccessResponse = try await networkService.request(.redirect(clientToken: clientToken, url: url))
        return true
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken,
                                    completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>) {
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
        let response: Response.Body.VaultedPaymentMethods = try await networkService.request(
            .fetchVaultedPaymentMethods(clientToken: clientToken)
        )
        AppState.current.selectedPaymentMethodId = response.data.first?.id
        return response
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
        try await networkService.request(
            .exchangePaymentMethodToken(
                clientToken: clientToken,
                vaultedPaymentMethodId: vaultedPaymentMethodId,
                vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData
            )
        )
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String, completion: @escaping APICompletion<Void>) {
        let endpoint = PrimerAPI.deleteVaultedPaymentMethod(clientToken: clientToken, id: id)
        networkService.request(endpoint) { (result: Result<SuccessResponse, Error>) in
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
        do {
            let _: SuccessResponse = try await networkService.request(
                .deleteVaultedPaymentMethod(clientToken: clientToken, id: id)
            )
        } catch {
            ErrorHandler.shared.handle(error: error)
            throw error
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

    func fetchConfiguration(
        clientToken: DecodedJWTToken,
        requestParameters: Request.URLParameters.Configuration?
    ) async throws -> (PrimerAPIConfiguration, [String: String]?) {
        do {
            return try await networkService.request(
                .fetchConfiguration(
                    clientToken: clientToken,
                    requestParameters: requestParameters
                ),
                retryConfig: RetryConfig(enabled: true)
            )
        } catch {
            ErrorHandler.shared.handle(error: error)
            throw error
        }
    }

    func createPayPalOrderSession(clientToken: DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>) {
        let endpoint = PrimerAPI.createPayPalOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        execute(endpoint, completion: completion)
    }

    func createPayPalOrderSession(
        clientToken: DecodedJWTToken,
        payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder
    ) async throws -> Response.Body.PayPal.CreateOrder {
        try await networkService.request(
            .createPayPalOrderSession(
                clientToken: clientToken,
                payPalCreateOrderRequest: payPalCreateOrderRequest
            )
        )
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
                                             completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>) {
        let endpoint = PrimerAPI.createPayPalBillingAgreementSession(clientToken: clientToken,
                                                                     payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        execute(endpoint, completion: completion)
    }

    func createPayPalBillingAgreementSession(
        clientToken: DecodedJWTToken,
        payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement
    ) async throws -> Response.Body.PayPal.CreateBillingAgreement {
        try await networkService.request(
            .createPayPalBillingAgreementSession(
                clientToken: clientToken,
                payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest
            )
        )
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
                                       completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>) {
        let endpoint = PrimerAPI.confirmPayPalBillingAgreement(clientToken: clientToken,
                                                               payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        execute(endpoint, completion: completion)
    }

    func confirmPayPalBillingAgreement(
        clientToken: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement
    ) async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        try await networkService.request(
            .confirmPayPalBillingAgreement(
                clientToken: clientToken,
                payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest
            )
        )
    }

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping APICompletion<Response.Body.Klarna.PaymentSession>) {
        let endpoint = PrimerAPI.createKlarnaPaymentSession(clientToken: clientToken,
                                                            klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
        execute(endpoint, completion: completion)
    }

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession
    ) async throws -> Response.Body.Klarna.PaymentSession {
        try await networkService.request(
            .createKlarnaPaymentSession(
                clientToken: clientToken,
                klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest
            )
        )
    }

    func createKlarnaCustomerToken(clientToken: DecodedJWTToken,
                                   klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
                                   completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {
        let endpoint = PrimerAPI.createKlarnaCustomerToken(clientToken: clientToken,
                                                           klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest)
        execute(endpoint, completion: completion)
    }

    func createKlarnaCustomerToken(
        clientToken: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken
    ) async throws -> Response.Body.Klarna.CustomerToken {
        try await networkService.request(
            .createKlarnaCustomerToken(
                clientToken: clientToken,
                klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest
            )
        )
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedJWTToken,
                                      klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
                                      completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {
        let endpoint = PrimerAPI.finalizeKlarnaPaymentSession(clientToken: clientToken,
                                                              klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        execute(endpoint, completion: completion)
    }

    func finalizeKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession
    ) async throws -> Response.Body.Klarna.CustomerToken {
        try await networkService.request(
            .finalizeKlarnaPaymentSession(
                clientToken: clientToken,
                klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest
            )
        )
    }

    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping APICompletion<BanksListSessionResponse>) {
        let endpoint = PrimerAPI.listAdyenBanks(clientToken: clientToken, request: request)
        execute(endpoint, completion: completion)
    }

    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList
    ) async throws -> BanksListSessionResponse {
        try await networkService.request(
            .listAdyenBanks(
                clientToken: clientToken,
                request: request
            )
        )
    }

    func listRetailOutlets(clientToken: DecodedJWTToken,
                           paymentMethodId: String,
                           completion: @escaping APICompletion<RetailOutletsList>) {
        let endpoint = PrimerAPI.listRetailOutlets(clientToken: clientToken, paymentMethodId: paymentMethodId)
        execute(endpoint, completion: completion)
    }

    func listRetailOutlets(
        clientToken: DecodedJWTToken,
        paymentMethodId: String
    ) async throws -> RetailOutletsList {
        try await networkService.request(
            .listRetailOutlets(
                clientToken: clientToken,
                paymentMethodId: paymentMethodId
            )
        )
    }

    func poll(
        clientToken: DecodedJWTToken?,
        url: String,
        retryConfig: RetryConfig? = nil,
        completion: @escaping APICompletion<PollingResponse>
    ) {
        networkService.request(
            PrimerAPI.poll(clientToken: clientToken, url: url),
            retryConfig: retryConfig) { (result: Result<PollingResponse, Error>, _) in
                switch result {
                case let .success(response): completion(.success(response))
                case let .failure(error): completion(.failure(handled(error: error)))
                }
            }
    }

    func poll(
        clientToken: DecodedJWTToken?,
        url: String
    ) async throws -> PollingResponse {
        try await networkService.request(
            .poll(
                clientToken: clientToken,
                url: url
            )
        )
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

    func requestPrimerConfigurationWithActions(
        clientToken: DecodedJWTToken,
        request: ClientSessionUpdateRequest
    ) async throws -> (PrimerAPIConfiguration, [String: String]?) {
        do {
            return try await networkService.request(
                .requestPrimerConfigurationWithActions(
                    clientToken: clientToken,
                    request: request
                )
            )
        } catch {
            ErrorHandler.shared.handle(error: error)
            throw error
        }
    }

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL,
                             body: [Analytics.Event]?,
                             completion: @escaping APICompletion<Analytics.Service.Response>) {
        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: clientToken, url: url, body: body)
        execute(endpoint, completion: completion)
    }

    func sendAnalyticsEvents(
        clientToken: DecodedJWTToken?,
        url: URL,
        body: [Analytics.Event]?
    ) async throws -> Analytics.Service.Response {
        try await networkService.request(
            .sendAnalyticsEvents(
                clientToken: clientToken,
                url: url,
                body: body
            )
        )
    }

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>) {
        let endpoint = PrimerAPI.fetchPayPalExternalPayerInfo(clientToken: clientToken,
                                                              payPalExternalPayerInfoRequestBody: payPalExternalPayerInfoRequestBody)
        execute(endpoint, completion: completion)
    }

    func fetchPayPalExternalPayerInfo(
        clientToken: DecodedJWTToken,
        payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo
    ) async throws -> Response.Body.PayPal.PayerInfo {
        try await networkService.request(
            .fetchPayPalExternalPayerInfo(
                clientToken: clientToken,
                payPalExternalPayerInfoRequestBody: payPalExternalPayerInfoRequestBody
            )
        )
    }

    func validateClientToken(request: Request.Body.ClientTokenValidation,
                             completion: @escaping APICompletion<SuccessResponse>) {
        let endpoint = PrimerAPI.validateClientToken(request: request)
        execute(endpoint, completion: completion)
    }

    func validateClientToken(request: Request.Body.ClientTokenValidation) async throws -> SuccessResponse {
        try await networkService.request(
            .validateClientToken(
                request: request
            )
        )
    }

    func createPayment(clientToken: DecodedJWTToken,
                       paymentRequestBody: Request.Body.Payment.Create,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
        let endpoint = PrimerAPI.createPayment(clientToken: clientToken, paymentRequest: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create
    ) async throws -> Response.Body.Payment {
        try await networkService.request(
            .createPayment(
                clientToken: clientToken,
                paymentRequest: paymentRequestBody
            )
        )
    }

    func resumePayment(clientToken: DecodedJWTToken,
                       paymentId: String,
                       paymentResumeRequest: Request.Body.Payment.Resume,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
        let endpoint = PrimerAPI.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest)
        execute(endpoint, completion: completion)
    }

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume
    ) async throws -> Response.Body.Payment {
        try await networkService.request(
            .resumePayment(
                clientToken: clientToken,
                paymentId: paymentId,
                paymentResumeRequest: paymentResumeRequest
            )
        )
    }

    func completePayment(clientToken: DecodedJWTToken,
                         url: URL,
                         paymentRequest: Request.Body.Payment.Complete,
                         completion: @escaping APICompletion<Response.Body.Complete>) {
        let endpoint = PrimerAPI.completePayment(clientToken: clientToken, url: url, paymentRequest: paymentRequest)
        execute(endpoint, completion: completion)
    }

    func completePayment(
        clientToken: DecodedJWTToken,
        url: URL,
        paymentRequest: Request.Body.Payment.Complete
    ) async throws -> Response.Body.Complete {
        try await networkService.request(
            .completePayment(
                clientToken: clientToken,
                url: url,
                paymentRequest: paymentRequest
            )
        )
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

    func testFinalizePolling(
        clientToken: DecodedJWTToken,
        testId: String
    ) async throws {
        let _: Response.Body.Payment = try await networkService.request(
            .testFinalizePolling(
                clientToken: clientToken,
                testId: testId
            )
        )
    }

    func listCardNetworks(clientToken: DecodedJWTToken,
                          bin: String,
                          completion: @escaping APICompletion<Response.Body.Bin.Networks>) -> PrimerCancellable? {
        let endpoint = PrimerAPI.listCardNetworks(clientToken: clientToken, bin: bin)
        return execute(endpoint, completion: completion)
    }

    func listCardNetworks(
        clientToken: DecodedJWTToken,
        bin: String
    ) async throws -> Response.Body.Bin.Networks {
        try await networkService.request(
            .listCardNetworks(
                clientToken: clientToken,
                bin: bin
            )
        )
    }

    func fetchNolSdkSecret(clientToken: DecodedJWTToken,
                           paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
                           completion: @escaping APICompletion<Response.Body.NolPay.NolPaySecretDataResponse>) {
        let endpoint = PrimerAPI.getNolSdkSecret(clientToken: clientToken, request: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func fetchNolSdkSecret(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest
    ) async throws -> Response.Body.NolPay.NolPaySecretDataResponse {
        try await networkService.request(
            .getNolSdkSecret(
                clientToken: clientToken,
                request: paymentRequestBody
            )
        )
    }

    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
                          completion: @escaping APICompletion<Response.Body.PhoneMetadata.PhoneMetadataDataResponse>) {
        let endpoint = PrimerAPI.getPhoneMetadata(clientToken: clientToken,
                                                  request: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func getPhoneMetadata(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest
    ) async throws -> Response.Body.PhoneMetadata.PhoneMetadataDataResponse {
        try await networkService.request(
            .getPhoneMetadata(
                clientToken: clientToken,
                request: paymentRequestBody
            )
        )
    }
}

private extension NetworkServiceProtocol {
    func request<T: Decodable>(_ primerAPI: PrimerAPI) async throws -> T {
        try await request(primerAPI)
    }

    func request<T: Decodable>(_ primerAPI: PrimerAPI) async throws -> (T, [String: String]?) {
        try await request(primerAPI)
    }

    func request<T: Decodable>(_ primerAPI: PrimerAPI, retryConfig: RetryConfig) async throws -> (T, [String: String]?) {
        try await request(primerAPI as Endpoint, retryConfig: retryConfig)
    }
}

private extension PrimerAPIClient {
    @discardableResult
    func execute<T>(_ endpoint: Endpoint, completion: @escaping APICompletion<T>) -> PrimerCancellable? where T: Decodable {
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

    func execute<T>(_ endpoint: Endpoint) async throws -> T where T: Decodable {
        do {
            return try await networkService.request(endpoint)
        } catch {
            ErrorHandler.shared.handle(error: error)
            throw error
        }
    }
}
