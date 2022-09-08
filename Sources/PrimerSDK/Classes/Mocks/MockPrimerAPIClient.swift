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

    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (Result<Response.Body.VaultedPaymentMethods, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(Response.Body.VaultedPaymentMethods.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void) {
        
    }
    
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken) -> Promise<Response.Body.VaultedPaymentMethods> {
        return Promise { seal in
            do {
                let value = try JSONDecoder().decode(Response.Body.VaultedPaymentMethods.self, from: response!)
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

    func fetchConfiguration(
        clientToken: DecodedClientToken,
        requestParameters: Request.URLParameters.Configuration?,
        completion: @escaping (Result<PrimerAPIConfiguration, Error>) -> Void)
    {
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

    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder, completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(Response.Body.PayPal.CreateOrder.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement, completion: @escaping (Result<Response.Body.PayPal.CreateBillingAgreement, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(Response.Body.PayPal.CreateBillingAgreement.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement, completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(Response.Body.PayPal.ConfirmBillingAgreement.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession, completion: @escaping (Result<Response.Body.Klarna.CreatePaymentSession, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil, diagnosticsId: nil)))
            return
        }
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(Response.Body.Klarna.CreatePaymentSession.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken, completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil, diagnosticsId: nil)))
            return
        }

        guard let response = response else { return }
        do {
            let value = try JSONDecoder().decode(Response.Body.Klarna.CustomerToken.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession, completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void) {
        isCalled = true

        guard throwsError == false else {
            completion(.failure(PrimerError.generic(message: "Mocked error", userInfo: nil, diagnosticsId: nil)))
            return
        }

        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(Response.Body.Klarna.CustomerToken.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, tokenizationRequestBody: Request.Body.Tokenization, completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(PrimerPaymentMethodTokenData.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func createApayaSession(
        clientToken: DecodedClientToken,
        request: Request.Body.Apaya.CreateSession,
        completion: @escaping (Result<Response.Body.Apaya.CreateSession, Error>) -> Void
    ) {
        isCalled = true
        guard let response = response else { return }
        
        do {
            let value = try JSONDecoder().decode(Response.Body.Apaya.CreateSession.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func listAdyenBanks(clientToken: DecodedClientToken, request: Request.Body.Adyen.BanksList, completion: @escaping (Result<[Response.Body.Adyen.Bank], Error>) -> Void) {
        
    }
    
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (Result<PollingResponse, Error>) -> Void) {
        
    }
    
    func sendAnalyticsEvents(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void) {
        
    }
    
    func threeDSBeginAuth(clientToken: DecodedClientToken, paymentMethodTokenData: PrimerPaymentMethodTokenData, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
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
    
    func fetchPayPalExternalPayerInfo(clientToken: DecodedClientToken, payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(Response.Body.PayPal.PayerInfo.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }

    }

    func createPayment(clientToken: DecodedClientToken, paymentRequestBody: Request.Body.Payment.Create, completion: @escaping (Result<Response.Body.Payment, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(Response.Body.Payment.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func resumePayment(clientToken: DecodedClientToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping (_ result: Result<Response.Body.Payment, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(Response.Body.Payment.self, from: response)
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
    
    func begin3DSAuth(clientToken: DecodedClientToken, paymentMethodTokenData: PrimerPaymentMethodTokenData, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
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
    
    func validateClientToken(request: Request.Body.ClientTokenValidation, completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        
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
