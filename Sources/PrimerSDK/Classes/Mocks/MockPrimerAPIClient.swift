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

    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (Result<PaymentMethod.Tokenization.Response, Error>) -> Void) {
        
    }
    
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse> {
        return Promise { seal in
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
        guard response != nil else { return }
        
        do {
            completion(.success(()))
        }
//        catch {
//            completion(.failure(error))
//        }
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

    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PaymentMethod.PayPal.CreateOrder.Request, completion: @escaping (Result<PaymentMethod.PayPal.CreateOrder.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PaymentMethod.PayPal.CreateOrder.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PaymentMethod.PayPal.CreateBillingAgreement.Request, completion: @escaping (Result<PaymentMethod.PayPal.CreateBillingAgreement.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PaymentMethod.PayPal.CreateBillingAgreement.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PaymentMethod.PayPal.ConfirmBillingAgreement.Request, completion: @escaping (Result<PaymentMethod.PayPal.ConfirmBillingAgreement.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PaymentMethod.PayPal.ConfirmBillingAgreement.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil)))
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
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil)))
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
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil)))
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

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: PaymentMethod.Tokenization.Request, completion: @escaping (Result<PaymentMethod.Tokenization.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PaymentMethod.Tokenization.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func createApayaSession(
        clientToken: DecodedClientToken,
        request: PaymentMethod.Apaya.CreateSessionAPIRequest,
        completion: @escaping (Result<PaymentMethod.Apaya.CreateSessionAPIResponse, Error>) -> Void
    ) {
        isCalled = true
        guard let response = response else { return }
        
        do {
            let value = try JSONDecoder().decode(PaymentMethod.Apaya.CreateSessionAPIResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func listAdyenBanks(clientToken: DecodedClientToken, request: PaymentMethod.Bank.Session.Request, completion: @escaping (Result<[PaymentMethod.Bank], Error>) -> Void) {
        
    }
    
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (Result<PollingResponse, Error>) -> Void) {
        
    }
    
    func sendAnalyticsEvents(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void) {
        
    }
    
    func threeDSBeginAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethod.Tokenization.Response, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
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
    
    func fetchPayPalExternalPayerInfo(clientToken: DecodedClientToken, payPalExternalPayerInfoRequestBody: PaymentMethod.PayPal.PayerInfo.Request, completion: @escaping (Result<PaymentMethod.PayPal.PayerInfo.Response, Error>) -> Void) {
        
    }
    
    func validateClientToken(request: ClientTokenValidationRequest, completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
                
        do {
            let value = try JSONDecoder().decode(SuccessResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
}

#endif
