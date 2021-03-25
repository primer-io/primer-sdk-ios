//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

protocol PrimerAPIClientProtocol {
    func vaultFetchPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<GetVaultedPaymentMethodsResponse, Error>) -> Void)
    func vaultDeletePaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Data, Error>) -> Void)
    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<PaymentMethodConfig, Error>) -> Void)
    func directDebitCreateMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void)
    func payPalStartOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void)
    func payPalStartBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void)
    func payPalConfirmBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
    func klarnaCreatePaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void)
    func klarnaFinalizePaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void)
    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: PaymentMethodTokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void)
}

class PrimerAPIClient: PrimerAPIClientProtocol {

    private let networkService: NetworkService

    // MARK: - Object lifecycle

    init(networkService: NetworkService = URLSessionStack()) {
        self.networkService = networkService
    }

    func vaultFetchPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<GetVaultedPaymentMethodsResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.vaultFetchPaymentMethods(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<GetVaultedPaymentMethodsResponse, NetworkServiceError>) in
            switch result {
            case .success(let vaultedPaymentMethodsResponse):
                completion(.success(vaultedPaymentMethodsResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.VaultFetchFailed))
            }
        }
    }

    func vaultDeletePaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
        let endpoint = PrimerAPI.vaultDeletePaymentMethod(clientToken: clientToken, id: id)
        networkService.request(endpoint) { (result: Result<Data, NetworkServiceError>) in
            switch result {
            case .success(let vaultedPaymentMethodsResponse):
                completion(.success(vaultedPaymentMethodsResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.VaultDeleteFailed))
            }
        }
    }

    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<PaymentMethodConfig, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<PaymentMethodConfig, NetworkServiceError>) in
            switch result {
            case .success(let paymentMethodConfig):
                completion(.success(paymentMethodConfig))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.ConfigFetchFailed))
            }
        }
    }

    func directDebitCreateMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.directDebitCreateMandate(clientToken: clientToken, mandateRequest: mandateRequest)
        networkService.request(endpoint) { (result: Result<DirectDebitCreateMandateResponse, NetworkServiceError>) in
            switch result {
            case .success(let paymentMethodConfig):
                completion(.success(paymentMethodConfig))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.ConfigFetchFailed))
            }
        }
    }

    func payPalStartOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.payPalStartOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateOrderResponse, NetworkServiceError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.PayPalSessionFailed))
            }
        }
    }

    func payPalStartBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.payPalStartBillingAgreementSession(clientToken: clientToken, payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateBillingAgreementResponse, NetworkServiceError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.PayPalSessionFailed))
            }
        }
    }

    func payPalConfirmBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.payPalConfirmBillingAgreement(clientToken: clientToken, payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalConfirmBillingAgreementResponse, NetworkServiceError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.PayPalSessionFailed))
            }
        }
    }

    func klarnaCreatePaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.klarnaCreatePaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCreatePaymentSessionAPIResponse, NetworkServiceError>) in
            switch result {
            case .success(let klarnaCreatePaymentSessionAPIResponse):
                completion(.success(klarnaCreatePaymentSessionAPIResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(KlarnaException.failedApiCall))
            }
        }
    }

    func klarnaFinalizePaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void) {
        let endpoint = PrimerAPI.klarnaFinalizePaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        networkService.request(endpoint) { (result: Result<KlarnaFinalizePaymentSessionresponse, NetworkServiceError>) in
            switch result {
            case .success(let klarnaFinalizePaymentSessionResponse):
                completion(.success(klarnaFinalizePaymentSessionResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(KlarnaException.failedApiCall))
            }
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: PaymentMethodTokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void) {
        let endpoint = PrimerAPI.tokenizePaymentMethod(clientToken: clientToken, paymentMethodTokenizationRequest: paymentMethodTokenizationRequest)
        networkService.request(endpoint) { (result: Result<PaymentMethodToken, NetworkServiceError>) in
            switch result {
            case .success(let paymentMethodToken):
                completion(.success(paymentMethodToken))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.TokenizationRequestFailed))
            }
        }
    }

}

class MockPrimerAPIClient: PrimerAPIClientProtocol {

    let response: Data?
    let throwsError: Bool
    var isCalled: Bool = false

    init(with response: Data? = nil, throwsError: Bool = false) {
        self.response = response
        self.throwsError = throwsError
    }

    func vaultFetchPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (Result<GetVaultedPaymentMethodsResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(GetVaultedPaymentMethodsResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func vaultDeletePaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (Result<Data, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(Data.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (Result<PaymentMethodConfig, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PaymentMethodConfig.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func directDebitCreateMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(DirectDebitCreateMandateResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func payPalStartOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (Result<PayPalCreateOrderResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalCreateOrderResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func payPalStartBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (Result<PayPalCreateBillingAgreementResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalCreateBillingAgreementResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func payPalConfirmBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalConfirmBillingAgreementResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func klarnaCreatePaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(KlarnaException.failedApiCall))
            return
        }
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(KlarnaCreatePaymentSessionAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func klarnaFinalizePaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(KlarnaFinalizePaymentSessionresponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: PaymentMethodTokenizationRequest, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PaymentMethodToken.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

}

#endif
