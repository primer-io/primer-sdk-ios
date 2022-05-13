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

    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        
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

    func fetchConfiguration(clientToken: DecodedClientToken, completion: @escaping (Result<PrimerAPIConfiguration, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PrimerAPIConfiguration.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

//    func createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
//        isCalled = true
//        guard let response = response else { return }
//
//        do {
//            let value = try JSONDecoder().decode(DirectDebitCreateMandateResponse.self, from: response)
//            completion(.success(value))
//        } catch {
//            completion(.failure(error))
//        }
//    }

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
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil, diagnosticsId: nil)))
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
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil, diagnosticsId: nil)))
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
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil, diagnosticsId: nil)))
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
    
    func sendAnalyticsEvents(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void) {
        
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
    
    func fetchPayPalExternalPayerInfo(clientToken: DecodedClientToken, payPalExternalPayerInfoRequestBody: PayPal.PayerInfo.Request, completion: @escaping (Result<PayPal.PayerInfo.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(PayPal.PayerInfo.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }

    }

    func createPayment(clientToken: DecodedClientToken, paymentRequestBody: Payment.CreateRequest, completion: @escaping (Result<Payment.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(Payment.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func resumePayment(clientToken: DecodedClientToken, paymentId: String, paymentResumeRequest: Payment.ResumeRequest, completion: @escaping (_ result: Result<Payment.Response, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(Payment.Response.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
}

extension MockPrimerAPIClient {
    
    func requestPrimerConfigurationWithActions(clientToken: DecodedClientToken, request: ClientSessionUpdateRequest, completion: @escaping (Result<PrimerAPIConfiguration, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(PrimerAPIConfiguration.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
}

extension MockPrimerAPIClient {
    
    func begin3DSAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
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
    
    func continue3DSAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
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
