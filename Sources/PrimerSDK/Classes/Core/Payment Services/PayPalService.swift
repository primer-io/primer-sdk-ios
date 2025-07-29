//
//  PayPalService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation

internal protocol PayPalServiceProtocol {
    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void)
    func startOrderSession() async throws -> Response.Body.PayPal.CreateOrder
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func startBillingAgreementSession() async throws -> String
    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void)
    func confirmBillingAgreement() async throws -> Response.Body.PayPal.ConfirmBillingAgreement
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void)
    func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo
}

final class PayPalService: PayPalServiceProtocol {

    private var paypalTokenId: String?
    private var apiConfig: PrimerAPIConfiguration? { PrimerAPIConfigurationModule.apiConfiguration }

    let apiClient: PrimerAPIClientPayPalProtocol

    init(apiClient: PrimerAPIClientPayPalProtocol = PrimerAPIClient()) {
        self.apiClient = apiClient
    }

    // swiftlint:disable:next large_tuple
    private func prepareUrlAndTokenAndId(path: String) -> (DecodedJWTToken, URL, String)? {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return nil
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
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
            return completion(.failure(handled(primerError: .invalidClientToken())))
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            return completion(.failure(handled(primerError: .invalidValue(key: "configuration.paypal.id"))))
        }

        guard let amount = AppState.current.amount else {
            return completion(.failure(handled(primerError: .invalidValue(key: "amount"))))
        }

        guard let currency = AppState.current.currency else {
            return completion(.failure(handled(primerError: .invalidValue(key: "currency"))))
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
                completion(.failure(handled(primerError: .failedToCreateSession(error: err))))
            case .success(let res):
                completion(.success(res))
            }
        }
    }

    func startOrderSession() async throws -> Response.Body.PayPal.CreateOrder {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            throw handled(primerError: .invalidValue(key: "configuration.paypal.id"))
        }

        guard let amount = AppState.current.amount else {
            throw handled(primerError: .invalidValue(key: "amount"))
        }

        guard let currency = AppState.current.currency else {
            throw handled(primerError: .invalidValue(key: "currency"))
        }

        let scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        let body = Request.Body.PayPal.CreateOrder(
            paymentMethodConfigId: configId,
            amount: amount,
            currencyCode: currency.code,
            returnUrl: "\(scheme)://paypal-success",
            cancelUrl: "\(scheme)://paypal-cancel"
        )

        do {
            return try await apiClient.createPayPalOrderSession(clientToken: decodedJWTToken, payPalCreateOrderRequest: body)
        } catch {
            throw handled(primerError: .failedToCreateSession(error: error))
        }
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return completion(.failure(handled(primerError: .invalidClientToken())))
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            return completion(.failure(handled(primerError: .invalidValue(key: "configuration.paypal.id"))))
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
                completion(.failure(handled(primerError: .failedToCreateSession(error: err))))
            case .success(let config):
                self?.paypalTokenId = config.tokenId
                completion(.success(config.approvalUrl))
            }
        }
    }

    func startBillingAgreementSession() async throws -> String {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            throw handled(primerError: .invalidValue(key: "configuration.paypal.id"))
        }

        let scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        let body = Request.Body.PayPal.CreateBillingAgreement(
            paymentMethodConfigId: configId,
            returnUrl: "\(scheme)://paypal-success",
            cancelUrl: "\(scheme)://paypal-cancel"
        )

        do {
            let result = try await apiClient.createPayPalBillingAgreementSession(
                clientToken: decodedJWTToken,
                payPalCreateBillingAgreementRequest: body
            )
            paypalTokenId = result.tokenId
            return result.approvalUrl
        } catch {
            throw handled(primerError: .failedToCreateSession(error: error))
        }
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return completion(.failure(handled(primerError: .invalidClientToken())))
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            return completion(.failure(handled(primerError: .invalidValue(key: "configuration.paypal.id"))))
        }

        guard let paypalTokenId else {
            return completion(.failure(handled(primerError: .invalidValue(key: "paypalTokenId", value: paypalTokenId))))
        }

        let body = Request.Body.PayPal.ConfirmBillingAgreement(paymentMethodConfigId: configId, tokenId: paypalTokenId)

        apiClient.confirmPayPalBillingAgreement(clientToken: decodedJWTToken,
                                                payPalConfirmBillingAgreementRequest: body) { result in
            switch result {
            case .failure(let err):
                completion(.failure(handled(primerError: .failedToCreateSession(error: err))))
            case .success(let response):
                completion(.success(response))
            }
        }
    }

    func confirmBillingAgreement() async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            throw handled(primerError: .invalidValue(key: "configuration.paypal.id"))
        }

        guard let paypalTokenId else {
            throw handled(primerError: .invalidValue(key: "paypalTokenId"))
        }

        do {
            return try await apiClient.confirmPayPalBillingAgreement(
                clientToken: decodedJWTToken,
                payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement(
                    paymentMethodConfigId: configId,
                    tokenId: paypalTokenId
                )
            )
        } catch {
            throw handled(primerError: .failedToCreateSession(error: error))
        }
    }

    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void) {
        let state: AppStateProtocol = AppState.current

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return completion(.failure(handled(primerError: .invalidClientToken())))
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            return completion(.failure(handled(primerError: .invalidValue(key: "configuration.paypal.id"))))
        }

        apiClient.fetchPayPalExternalPayerInfo(
            clientToken: decodedJWTToken,
            payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo(paymentMethodConfigId: configId, orderId: orderId)
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let configId = apiConfig?.getConfigId(for: PrimerPaymentMethodType.payPal.rawValue) else {
            throw handled(primerError: .invalidValue(key: "configuration.paypal.id"))
        }

        return try await apiClient.fetchPayPalExternalPayerInfo(
            clientToken: decodedJWTToken,
            payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo(
                paymentMethodConfigId: configId,
                orderId: orderId
            )
        )
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
