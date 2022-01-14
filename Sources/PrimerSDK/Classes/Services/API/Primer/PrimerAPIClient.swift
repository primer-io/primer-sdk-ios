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
    func vaultFetchPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse>
    func vaultDeletePaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Data, Error>) -> Void)
    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<PrimerConfiguration, Error>) -> Void)
    func directDebitCreateMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void)
    func payPalStartOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void)
    func payPalStartBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void)
    func payPalConfirmBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
    func klarnaCreatePaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void)
    func klarnaCreateCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void)
    func klarnaFinalizePaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void)
    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void)
    func threeDSBeginAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func threeDSContinueAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void)
    func apayaCreateSession(clientToken: DecodedClientToken, request: Apaya.CreateSessionAPIRequest, completion: @escaping (_ result: Result<Apaya.CreateSessionAPIResponse, Error>) -> Void)
    func adyenBanksList(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (_ result: Result<[Bank], Error>) -> Void)
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void)
    
    func sendAnalyticsEvent(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void)
}

internal class PrimerAPIClient: PrimerAPIClientProtocol {
    
    internal let networkService: NetworkService

    // MARK: - Object lifecycle
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    init(networkService: NetworkService = URLSessionStack()) {
        self.networkService = networkService
    }

    func vaultFetchPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<GetVaultedPaymentMethodsResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.vaultFetchPaymentMethods(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<GetVaultedPaymentMethodsResponse, NetworkError>) in
            switch result {
            case .success(let vaultedPaymentMethodsResponse):
                let state: AppStateProtocol = DependencyContainer.resolve()
                state.selectedPaymentMethodToken = vaultedPaymentMethodsResponse.data.first?.token
                completion(.success(vaultedPaymentMethodsResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func vaultDeletePaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
        let endpoint = PrimerAPI.vaultDeletePaymentMethod(clientToken: clientToken, id: id)
        networkService.request(endpoint) { (result: Result<Data, NetworkError>) in
            switch result {
            case .success(let vaultedPaymentMethodsResponse):
                completion(.success(vaultedPaymentMethodsResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<PrimerConfiguration, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<PrimerConfiguration, NetworkError>) in
            switch result {
            case .success(let primerConfiguration):
                completion(.success(primerConfiguration))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func directDebitCreateMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.directDebitCreateMandate(clientToken: clientToken, mandateRequest: mandateRequest)
        networkService.request(endpoint) { (result: Result<DirectDebitCreateMandateResponse, NetworkError>) in
            switch result {
            case .success(let primerConfiguration):
                completion(.success(primerConfiguration))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func payPalStartOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.payPalStartOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateOrderResponse, NetworkError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func payPalStartBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.payPalStartBillingAgreementSession(clientToken: clientToken, payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateBillingAgreementResponse, NetworkError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func payPalConfirmBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.payPalConfirmBillingAgreement(clientToken: clientToken, payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalConfirmBillingAgreementResponse, NetworkError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func klarnaCreatePaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.klarnaCreatePaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCreatePaymentSessionAPIResponse, NetworkError>) in
            switch result {
            case .success(let klarnaCreatePaymentSessionAPIResponse):
                completion(.success(klarnaCreatePaymentSessionAPIResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func klarnaCreateCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.klarnaCreateCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCustomerTokenAPIResponse, NetworkError>) in
            switch result {
            case .success(let klarnaCreateCustomerTokenAPIRequest):
                completion(.success(klarnaCreateCustomerTokenAPIRequest))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func klarnaFinalizePaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.klarnaFinalizePaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCustomerTokenAPIResponse, NetworkError>) in
            switch result {
            case .success(let klarnaFinalizePaymentSessionResponse):
                completion(.success(klarnaFinalizePaymentSessionResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void) {
        let endpoint = PrimerAPI.tokenizePaymentMethod(clientToken: clientToken, paymentMethodTokenizationRequest: paymentMethodTokenizationRequest)
        networkService.request(endpoint) { (result: Result<PaymentMethodToken, NetworkError>) in
            switch result {
            case .success(let paymentMethodToken):
                completion(.success(paymentMethodToken))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func apayaCreateSession(
        clientToken: DecodedClientToken,
        request: Apaya.CreateSessionAPIRequest,
        completion: @escaping (Result<Apaya.CreateSessionAPIResponse, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.apayaCreateSession(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<Apaya.CreateSessionAPIResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func adyenBanksList(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (Result<[Bank], Error>) -> Void) {
        let endpoint = PrimerAPI.adyenBanksList(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<BanksListSessionResponse, NetworkError>) in
            switch result {
            case .success(let res):
                let banks = res.result
                completion(.success(banks))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func poll(
        clientToken: DecodedClientToken?,
        url: String,
        completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.poll(clientToken: clientToken, url: url)
        networkService.request(endpoint) { (result: Result<PollingResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func sendAnalyticsEvent(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void) {
        let endpoint = PrimerAPI.sendAnalyticsEvents(url: url, body: body)
        networkService.request(endpoint) { (result: Result<Analytics.Service.Response, NetworkError>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}

#endif
