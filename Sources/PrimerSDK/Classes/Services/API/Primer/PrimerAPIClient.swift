//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

protocol PrimerAPIClientProtocol {
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<GetVaultedPaymentMethodsResponse, Error>) -> Void)
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse>
    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void)
    func deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Void, Error>) -> Void)
    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<PrimerConfiguration, Error>) -> Void)
    func createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void)
    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void)
    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void)
    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void)
    func createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void)
    func finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void)
    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void)
    func begin3DSAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func continue3DSAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void)
    func createApayaSession(clientToken: DecodedClientToken, request: Apaya.CreateSessionAPIRequest, completion: @escaping (_ result: Result<Apaya.CreateSessionAPIResponse, Error>) -> Void)
    func listAdyenBanks(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (_ result: Result<[Bank], Error>) -> Void)
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void)
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

    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<GetVaultedPaymentMethodsResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchVaultedPaymentMethods(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<GetVaultedPaymentMethodsResponse, NetworkServiceError>) in
            switch result {
            case .success(let vaultedPaymentMethodsResponse):
                let state: AppStateProtocol = DependencyContainer.resolve()
                state.selectedPaymentMethodId = vaultedPaymentMethodsResponse.data.first?.id
                completion(.success(vaultedPaymentMethodsResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.vaultFetchFailed))
            }
        }
    }
    
    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void) {
        let endpoint = PrimerAPI.exchangePaymentMethodToken(clientToken: clientToken, paymentMethodId: paymentMethodId)
        networkService.request(endpoint) { (result: Result<PaymentMethodToken, NetworkServiceError>) in
            switch result {
            case .success(let paymentInstrument):
                completion(.success(paymentInstrument))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.vaultFetchFailed))
            }
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        let endpoint = PrimerAPI.deleteVaultedPaymentMethod(clientToken: clientToken, id: id)
        networkService.request(endpoint) { (result: Result<DummySuccess, NetworkServiceError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.vaultDeleteFailed))
            }
        }
    }

    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<PrimerConfiguration, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<PrimerConfiguration, NetworkServiceError>) in
            switch result {
            case .success(let primerConfiguration):
                completion(.success(primerConfiguration))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.configFetchFailed))
            }
        }
    }

    func createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createDirectDebitMandate(clientToken: clientToken, mandateRequest: mandateRequest)
        networkService.request(endpoint) { (result: Result<DirectDebitCreateMandateResponse, NetworkServiceError>) in
            switch result {
            case .success(let primerConfiguration):
                completion(.success(primerConfiguration))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.configFetchFailed))
            }
        }
    }

    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createPayPalOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateOrderResponse, NetworkServiceError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.payPalSessionFailed))
            }
        }
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createPayPalSBillingAgreementSession(clientToken: clientToken, payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateBillingAgreementResponse, NetworkServiceError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.payPalSessionFailed))
            }
        }
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.confirmPayPalBillingAgreement(clientToken: clientToken, payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalConfirmBillingAgreementResponse, NetworkServiceError>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.payPalSessionFailed))
            }
        }
    }

    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createKlarnaPaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
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

    func createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createKlarnaCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCustomerTokenAPIResponse, NetworkServiceError>) in
            switch result {
            case .success(let klarnaCreateCustomerTokenAPIRequest):
                completion(.success(klarnaCreateCustomerTokenAPIRequest))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(KlarnaException.failedApiCall))
            }
        }
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.finalizeKlarnaPaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCustomerTokenAPIResponse, NetworkServiceError>) in
            switch result {
            case .success(let klarnaFinalizePaymentSessionResponse):
                completion(.success(klarnaFinalizePaymentSessionResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(KlarnaException.failedApiCall))
            }
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void) {
        let endpoint = PrimerAPI.tokenizePaymentMethod(clientToken: clientToken, paymentMethodTokenizationRequest: paymentMethodTokenizationRequest)
        networkService.request(endpoint) { (result: Result<PaymentMethodToken, NetworkServiceError>) in
            switch result {
            case .success(let paymentMethodToken):
                completion(.success(paymentMethodToken))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.tokenizationRequestFailed))
            }
        }
    }
    
    func createApayaSession(
        clientToken: DecodedClientToken,
        request: Apaya.CreateSessionAPIRequest,
        completion: @escaping (Result<Apaya.CreateSessionAPIResponse, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.createApayaSession(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<Apaya.CreateSessionAPIResponse, NetworkServiceError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(ApayaException.failedApiCall))
            }
        }
    }
    
    func listAdyenBanks(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (Result<[Bank], Error>) -> Void) {
        let endpoint = PrimerAPI.listAdyenBanks(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<BanksListSessionResponse, NetworkServiceError>) in
            switch result {
            case .success(let res):
                let banks = res.result
                print(banks)
                completion(.success(banks))
            case .failure(let error):
                _ = ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.tokenizationRequestFailed))
            }
        }
    }
    
    func poll(
        clientToken: DecodedClientToken?,
        url: String,
        completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.poll(clientToken: clientToken, url: url)
        networkService.request(endpoint) { (result: Result<PollingResponse, NetworkServiceError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error))
            }
        }
    }
}

internal class MockPrimerAPIClient: PrimerAPIClientProtocol {
    
    var response: Data?
    var throwsError: Bool
    var isCalled: Bool = false

    init(with response: Data? = nil, throwsError: Bool = false) {
        self.response = response
        self.throwsError = throwsError
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (Result<GetVaultedPaymentMethodsResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(GetVaultedPaymentMethodsResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        
    }
    
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse> {
        return Promise { [weak self] seal in
            do {
                let value = try JSONDecoder().decode(GetVaultedPaymentMethodsResponse.self, from: response!)
                seal.fulfill(value)
            } catch {
                seal.reject(error)
            }
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (Result<PrimerConfiguration, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PrimerConfiguration.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(DirectDebitCreateMandateResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (Result<PayPalCreateOrderResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalCreateOrderResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (Result<PayPalCreateBillingAgreementResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalCreateBillingAgreementResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PayPalConfirmBillingAgreementResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
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

    func createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(KlarnaException.failedApiCall))
            return
        }

        guard let response = response else { return }
        do {
            let value = try JSONDecoder().decode(KlarnaCustomerTokenAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(KlarnaException.failedApiCall))
            return
        }

        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(KlarnaCustomerTokenAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PaymentMethodToken.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func createApayaSession(
        clientToken: DecodedClientToken,
        request: Apaya.CreateSessionAPIRequest,
        completion: @escaping (Result<Apaya.CreateSessionAPIResponse, Error>) -> Void
    ) {
        isCalled = true
        guard let response = response else { return }
        
        do {
            let value = try JSONDecoder().decode(Apaya.CreateSessionAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func listAdyenBanks(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (Result<[Bank], Error>) -> Void) {
        
    }
    
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (Result<PollingResponse, Error>) -> Void) {
        
    }

}

#endif
