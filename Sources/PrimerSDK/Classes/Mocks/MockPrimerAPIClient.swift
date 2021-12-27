//
//  MockPrimerAPIClient.swift
//  PrimerSDK
//
//  Created by Evangelos on 23/12/21.
//

#if canImport(UIKit)

import Foundation

internal class MockPrimerAPIClient: PrimerAPIClientProtocol {
    
    var response: Data?
    var throwsError: Bool
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
    
    func vaultFetchPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse> {
        return Promise { [weak self] seal in
            do {
                let value = try JSONDecoder().decode(GetVaultedPaymentMethodsResponse.self, from: response!)
                seal.fulfill(value)
            } catch {
                seal.reject(error)
            }
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
            completion(.failure(NetworkError.connectivityErrors(errors: [NSError(domain: NSURLErrorDomain, code: -1001, userInfo: nil)])))
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

    func klarnaCreateCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(NetworkError.connectivityErrors(errors: [NSError(domain: NSURLErrorDomain, code: -1001, userInfo: nil)])))
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

    func klarnaFinalizePaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(NetworkError.connectivityErrors(errors: [NSError(domain: NSURLErrorDomain, code: -1001, userInfo: nil)])))
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
    
    func apayaCreateSession(
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
    
    func adyenBanksList(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (Result<[Bank], Error>) -> Void) {
        
    }
    
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (Result<PollingResponse, Error>) -> Void) {
        
    }
    
    func sendAnalyticsEvent(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void) {
        
    }
    
    func threeDSBeginAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.BeginAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func threeDSContinueAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        isCalled = true
        
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.PostAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
}

#endif

