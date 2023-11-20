//
//  MockAPIClient.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 24/4/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

@testable import PrimerSDK
import XCTest

class MockPrimerAPIClient: PrimerAPIClientProtocol {
    var mockedNetworkDelay: TimeInterval = 2
    var validateClientTokenResult: (SuccessResponse?, Error?)?
    var fetchConfigurationResult: (Response.Body.Configuration?, Error?)?
    var fetchConfigurationWithActionsResult: (Response.Body.Configuration?, Error?)?
    var fetchVaultedPaymentMethodsResult: (Response.Body.VaultedPaymentMethods?, Error?)?
    var deleteVaultedPaymentMethodResult: (Void?, Error?)?
    var createPayPalOrderSessionResult: (Response.Body.PayPal.CreateOrder?, Error?)?
    var createPayPalBillingAgreementSessionResult: (Response.Body.PayPal.CreateBillingAgreement?, Error?)?
    var confirmPayPalBillingAgreementResult: (Response.Body.PayPal.ConfirmBillingAgreement?, Error?)?
    var createKlarnaPaymentSessionResult: (Response.Body.Klarna.CreatePaymentSession?, Error?)?
    var createKlarnaCustomerTokenResult: (Response.Body.Klarna.CustomerToken?, Error?)?
    var finalizeKlarnaPaymentSessionResult: (Response.Body.Klarna.CustomerToken?, Error?)?
    var pollingResults: [(PollingResponse?, Error?)]?
    var tokenizePaymentMethodResult: (PrimerPaymentMethodTokenData?, Error?)?
    var exchangePaymentMethodTokenResult: (PrimerPaymentMethodTokenData?, Error?)?
    var begin3DSAuthResult: (ThreeDS.BeginAuthResponse?, Error?)?
    var continue3DSAuthResult: (ThreeDS.PostAuthResponse?, Error?)?
    var createApayaSessionResult: (Response.Body.Apaya.CreateSession?, Error?)?
    var listAdyenBanksResult: ([Response.Body.Adyen.Bank]?, Error?)?
    var listRetailOutletsResult: (RetailOutletsList?, Error?)?
    var paymentResult: (Response.Body.Payment?, Error?)?
    var sendAnalyticsEventsResult: (Analytics.Service.Response?, Error?)?
    var fetchPayPalExternalPayerInfoResult: (Response.Body.PayPal.PayerInfo?, Error?)?
    var resumePaymentResult: (Response.Body.Payment?, Error?)?
    var testFinalizePollingResult: (Void?, Error?)?
    var listCardNetworksResult: (Response.Body.Bin.Networks?, Error?)?
    private var currentPollingIteration: Int = 0
    var testFetchNolSdkSecretResult: (Response.Body.NolPay.NolPaySecretDataResponse?, Error?)?
    var phoneMetadataResult = Response.Body.PhoneMetadata.PhoneMetadataDataResponse(isValid: true, countryCode: "+111", nationalNumber: "12341234")
    
    func validateClientToken(
        request: Request.Body.ClientTokenValidation,
        completion: @escaping (_ result: Result<SuccessResponse, Error>) -> Void
    ) {
        guard let result = validateClientTokenResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'validateClientTokenResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) { 
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func fetchConfiguration(
        clientToken: DecodedJWTToken,
        requestParameters: Request.URLParameters.Configuration?,
        completion: @escaping (_ result: Result<Response.Body.Configuration, Error>) -> Void
    ) {
        guard let result = fetchConfigurationResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchConfigurationResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func fetchVaultedPaymentMethods(
        clientToken: DecodedJWTToken,
        completion: @escaping (_ result: Result<Response.Body.VaultedPaymentMethods, Error>) -> Void
    ) {
        guard let result = fetchVaultedPaymentMethodsResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchVaultedPaymentMethodsResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) -> Promise<Response.Body.VaultedPaymentMethods> {
        return Promise { seal in
            self.fetchVaultedPaymentMethods(clientToken: clientToken) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }
    
    func deleteVaultedPaymentMethod(
        clientToken: DecodedJWTToken,
        id: String,
        completion: @escaping (_ result: Result<Void, Error>) -> Void
    ) {
        guard let result = deleteVaultedPaymentMethodResult else {
            XCTAssert(false, "Set 'deleteVaultedPaymentMethodResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // PayPal
    func createPayPalOrderSession(
        clientToken: DecodedJWTToken,
        payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
        completion: @escaping (_ result: Result<Response.Body.PayPal.CreateOrder, Error>) -> Void
    ) {
        guard let result = createPayPalOrderSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createPayPalOrderSessionResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func createPayPalBillingAgreementSession(
        clientToken: DecodedJWTToken,
        payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
        completion: @escaping (_ result: Result<Response.Body.PayPal.CreateBillingAgreement, Error>) -> Void
    ) {
        guard let result = createPayPalBillingAgreementSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createPayPalBillingAgreementSessionResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func confirmPayPalBillingAgreement(
        clientToken: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
        completion: @escaping (_ result: Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void
    ) {
        guard let result = confirmPayPalBillingAgreementResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'confirmPayPalBillingAgreementResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    // Klarna
    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping (_ result: Result<Response.Body.Klarna.CreatePaymentSession, Error>) -> Void
    ) {
        guard let result = createKlarnaPaymentSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func createKlarnaCustomerToken(
        clientToken: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
        completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    ) {
        guard let result = createKlarnaCustomerTokenResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createKlarnaCustomerTokenResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func finalizeKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
        completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    ) {
        guard let result = finalizeKlarnaPaymentSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'finalizeKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    // Tokenization
    func tokenizePaymentMethod(
        clientToken: DecodedJWTToken,
        tokenizationRequestBody: Request.Body.Tokenization,
        completion: @escaping (_ result: Result<PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        guard let result = tokenizePaymentMethodResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'tokenizePaymentMethodResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func exchangePaymentMethodToken(
        clientToken: PrimerSDK.DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerSDK.PrimerVaultedPaymentMethodAdditionalData?,
        completion: @escaping (Result<PrimerSDK.PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        guard let result = exchangePaymentMethodTokenResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'tokenizePaymentMethodResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    // 3DS
    func begin3DSAuth(clientToken: DecodedJWTToken, paymentMethodTokenData: PrimerPaymentMethodTokenData, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void
    ) {
        guard let result = begin3DSAuthResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'begin3DSAuthResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func continue3DSAuth(clientToken: PrimerSDK.DecodedJWTToken, threeDSTokenId: String, continueInfo: PrimerSDK.ThreeDS.ContinueInfo, completion: @escaping (Result<PrimerSDK.ThreeDS.PostAuthResponse, Error>) -> Void) {
        guard let result = continue3DSAuthResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'continue3DSAuthResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    // Apaya
    func createApayaSession(
        clientToken: DecodedJWTToken,
        request: Request.Body.Apaya.CreateSession,
        completion: @escaping (_ result: Result<Response.Body.Apaya.CreateSession, Error>) -> Void
    ) {
        guard let result = createApayaSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createApayaSessionResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping (_ result: Result<[Response.Body.Adyen.Bank], Error>) -> Void
    ) {
        guard let result = listAdyenBanksResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'listAdyenBanksResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func listRetailOutlets(
        clientToken: PrimerSDK.DecodedJWTToken,
        paymentMethodId: String,
        completion: @escaping (Result<PrimerSDK.RetailOutletsList, Error>) -> Void) {
        guard let result = listRetailOutletsResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'listRetailOutletsResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func poll(
        clientToken: DecodedJWTToken?,
        url: String,
        completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void) {
        guard let pollingResults = pollingResults,
              !pollingResults.isEmpty
        else {
            XCTAssert(false, "Set 'pollingResults' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            let pollingResult = pollingResults[self.currentPollingIteration]
            self.currentPollingIteration += 1
            
            if pollingResult.0 == nil && pollingResult.1 == nil {
                XCTAssert(false, "Each 'pollingResult' must have a response or an error.")
            }
            
            if let err = pollingResult.1 {
                if self.currentPollingIteration == pollingResults.count {
                    XCTAssert(false, "Polling finished with error")
                } else {
                    self.poll(clientToken: clientToken, url: url, completion: completion)
                }
            } else if let res = pollingResult.0 {
                if res.status == .complete {
                    completion(.success(res))
                } else {
                    self.poll(clientToken: clientToken, url: url, completion: completion)
                }
            }
        }
    }
    
    func requestPrimerConfigurationWithActions(
        clientToken: DecodedJWTToken,
        request: ClientSessionUpdateRequest,
        completion: @escaping (_ result: Result<PrimerAPIConfiguration, Error>) -> Void) {
        guard let result = fetchConfigurationWithActionsResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchConfigurationWithActionsResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func sendAnalyticsEvents(clientToken: DecodedJWTToken?, url: URL, body: [Analytics.Event]?, completion: @escaping (Result<Analytics.Service.Response, Error>) -> Void) {
        guard let result = sendAnalyticsEventsResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'sendAnalyticsResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.async {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func fetchPayPalExternalPayerInfo(
        clientToken: DecodedJWTToken,
        payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
        completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void) {
        guard let result = fetchPayPalExternalPayerInfoResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchPayPalExternalPayerInfoResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    // Payment
    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping (_ result: Result<Response.Body.Payment, Error>) -> Void
    ) {
        guard let result = paymentResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'paymentResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
    
    func resumePayment(clientToken: DecodedJWTToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping (Result<Response.Body.Payment, Error>) -> Void) {
        guard let result = resumePaymentResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'resumePaymentResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }
        
    func testFinalizePolling(clientToken: PrimerSDK.DecodedJWTToken, testId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let result = testFinalizePollingResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'testFinalizePollingResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func listCardNetworks(clientToken: DecodedJWTToken, bin: String, completion: @escaping (Result<Response.Body.Bin.Networks, Error>) -> Void) -> PrimerCancellable? {
        guard let result = listCardNetworksResult, (result.0 != nil || result.1 != nil) else {
            XCTFail("Set 'listCardNetworksResult' on your MockPrimerAPIClient")
            return nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let res = result.0 {
                completion(.success(res))
            }
        }
        
        return nil
    }
    
    func fetchNolSdkSecret(clientToken: PrimerSDK.DecodedJWTToken, paymentRequestBody: PrimerSDK.Request.Body.NolPay.NolPaySecretDataRequest, completion: @escaping (Result<PrimerSDK.Response.Body.NolPay.NolPaySecretDataResponse, Error>) -> Void) {
        
        guard let result = testFetchNolSdkSecretResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'testFetchNolSdkSecretResult' on your MockPrimerAPIClient")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func genericAPICall(clientToken: PrimerSDK.DecodedJWTToken, url: URL, completion: @escaping (Result<Bool, Error>) -> Void) {
        Timer.scheduledTimer(withTimeInterval: self.mockedNetworkDelay, repeats: false) { _ in
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }
    }
    
    func getPhoneMetadata(clientToken: PrimerSDK.DecodedJWTToken, paymentRequestBody: PrimerSDK.Request.Body.PhoneMetadata.PhoneMetadataDataRequest, completion: @escaping (Result<PrimerSDK.Response.Body.PhoneMetadata.PhoneMetadataDataResponse, Error>) -> Void) {
        completion(.success(phoneMetadataResult))
    }

    func mockSuccessfulResponses() {
        self.validateClientTokenResult                  = (MockPrimerAPIClient.Samples.mockValidateClientToken, nil)
        self.fetchConfigurationResult                   = (MockPrimerAPIClient.Samples.mockPrimerAPIConfiguration, nil)
        self.fetchVaultedPaymentMethodsResult           = (MockPrimerAPIClient.Samples.mockVaultedPaymentMethods, nil)
        self.createPayPalOrderSessionResult             = (MockPrimerAPIClient.Samples.mockPayPalCreateOrder, nil)
        self.createPayPalBillingAgreementSessionResult  = (MockPrimerAPIClient.Samples.mockCreatePayPalBillingAgreementSession, nil)
        self.confirmPayPalBillingAgreementResult        = (MockPrimerAPIClient.Samples.mockConfirmPayPalBillingAgreement, nil)
        self.createKlarnaPaymentSessionResult           = (MockPrimerAPIClient.Samples.mockCreateKlarnaPaymentSession, nil)
        self.createKlarnaCustomerTokenResult            = (MockPrimerAPIClient.Samples.mockCreateKlarnaCustomerToken, nil)
        self.finalizeKlarnaPaymentSessionResult         = (MockPrimerAPIClient.Samples.mockFinalizeKlarnaPaymentSession, nil)
        self.pollingResults                             = MockPrimerAPIClient.Samples.mockPollingResults
        self.tokenizePaymentMethodResult                = (MockPrimerAPIClient.Samples.mockTokenizePaymentMethod, nil)
        self.exchangePaymentMethodTokenResult           = (MockPrimerAPIClient.Samples.mockExchangePaymentMethodToken, nil)
        self.begin3DSAuthResult                         = (MockPrimerAPIClient.Samples.mockBegin3DSAuth, nil)
        self.continue3DSAuthResult                      = (MockPrimerAPIClient.Samples.mockContinue3DSAuth, nil)
        self.createApayaSessionResult                   = (MockPrimerAPIClient.Samples.mockApayaSessionResult, nil)
        self.listAdyenBanksResult                       = (MockPrimerAPIClient.Samples.mockAdyenBanks, nil)
        self.listRetailOutletsResult                    = (MockPrimerAPIClient.Samples.mockListRetailOutlets, nil)
        self.paymentResult                              = (MockPrimerAPIClient.Samples.mockPayment, nil)
        self.resumePaymentResult                        = (MockPrimerAPIClient.Samples.mockResumePayment, nil)
        self.sendAnalyticsEventsResult                  = (MockPrimerAPIClient.Samples.mockSendAnalyticsEvents, nil)
        self.fetchPayPalExternalPayerInfoResult         = (MockPrimerAPIClient.Samples.mockFetchPayPalExternalPayerInfo, nil)
        self.testFetchNolSdkSecretResult                = (MockPrimerAPIClient.Samples.mockFetchNolSdkSecret, nil)
    }
}

extension MockPrimerAPIClient {
    
    class Samples {
        
        static let mockValidateClientToken: SuccessResponse = SuccessResponse(success: true)
        static let mockPrimerAPIConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: ClientSession.APIResponse(
                clientSessionId: "mock-client-session-id-1",
                paymentMethod: ClientSession.PaymentMethod(
                    vaultOnSuccess: false,
                    options: nil),
                order: ClientSession.Order(
                    id: "mock-client-session-order-id-1",
                    merchantAmount: nil,
                    totalOrderAmount: 100,
                    totalTaxAmount: nil,
                    countryCode: .gb,
                    currencyCode: .GBP,
                    fees: nil,
                    lineItems: [
                        ClientSession.Order.LineItem(
                            itemId: "mock-item-id-1",
                            quantity: 1,
                            amount: 100,
                            discountAmount: nil,
                            name: "mock-name-1",
                            description: "mock-description-1",
                            taxAmount: nil,
                            taxCode: nil)
                    ],
                    shippingAmount: nil),
                customer: nil,
                testId: nil),
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "mock-id-1",
                    implementationType: .webRedirect,
                    type: "ADYEN_GIROPAY",
                    name: "Giropay",
                    processorConfigId: "mock-processor-config-id-1",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil),
                PrimerPaymentMethod(
                    id: "mock-id-2",
                    implementationType: .webRedirect,
                    type: "ADYEN_DOTPAY",
                    name: "Payment Method Unavailable on Headless",
                    processorConfigId: "mock-processor-config-id-2",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil)
            ],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil)
        static let mockVaultedPaymentMethods = Response.Body.VaultedPaymentMethods(
            data: [])
        static let mockPayPalCreateOrder: Response.Body.PayPal.CreateOrder = Response.Body.PayPal.CreateOrder(
            orderId: "mock-id",
            approvalUrl: "https://primer.io/approval")
        static let mockCreatePayPalBillingAgreementSession = Response.Body.PayPal.CreateBillingAgreement(
            tokenId: "mock_token-id",
            approvalUrl: "https://primer.io/approval")
        static let mockConfirmPayPalBillingAgreement = Response.Body.PayPal.ConfirmBillingAgreement(
            billingAgreementId: "mock-paypal-billing-agreement-id",
            externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo(
                externalPayerId: "mock-external-payer-id",
                email: "john@email.com",
                firstName: "John",
                lastName: "Smith"),
            shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress(
                firstName: "John",
                lastName: "Smith",
                addressLine1: "Mock address line 1",
                addressLine2: "Mock address line 2",
                city: "London",
                state: "London Greater Area",
                countryCode: "GB",
                postalCode: "PC12345"))
        static let mockCreateKlarnaPaymentSession = Response.Body.Klarna.CreatePaymentSession(
            clientToken: "mock-client-token",
            sessionId: "mock-session-id",
            categories: [
                Response.Body.Klarna.SessionCategory(
                    identifier: "mock-session-category-id",
                    name: "mock-session-category-name",
                    descriptiveAssetUrl: "https://klarna.com/assets-descriptive",
                    standardAssetUrl: "https://klarna.com/assets-standard")
            ],
            hppSessionId: "mock-hpp-session-id",
            hppRedirectUrl: "https://klarna.com/redirect")
        static let mockCreateKlarnaCustomerToken = Response.Body.Klarna.CustomerToken(
            customerTokenId: "mock-customer-token-id",
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: "Mock recurring description",
                purchaseCountry: "SE",
                purchaseCurrency: "SEK",
                locale: "en-US",
                orderAmount: 100,
                orderLines: [
                    Response.Body.Klarna.SessionOrderLines(
                        type: "mock-type",
                        name: "mock-name",
                        quantity: 1,
                        unitPrice: 100,
                        totalAmount: 100,
                        totalDiscountAmount: 0)
                ],
                billingAddress: Response.Body.Klarna.BillingAddress(
                    addressLine1: "Mock address line 1",
                    addressLine2: "Mock address line 2",
                    addressLine3: "Mock address line 3",
                    city: "London",
                    countryCode: "GB",
                    email: "john@primer.io",
                    firstName: "John",
                    lastName: "Smith",
                    phoneNumber: "+447812345678",
                    postalCode: "PC123456",
                    state: "Greater London",
                    title: "Mock title"),
                tokenDetails: Response.Body.Klarna.TokenDetails(
                    brand: "Visa",
                    maskedNumber: "**** **** **** 1234",
                    type: "Visa",
                    expiryDate: "03/2030")))
        static let mockFinalizeKlarnaPaymentSession = Response.Body.Klarna.CustomerToken(
            customerTokenId: "mock-customer-token-id",
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: "Mock recurring description",
                purchaseCountry: "SE",
                purchaseCurrency: "SEK",
                locale: "en-US",
                orderAmount: 100,
                orderLines: [
                    Response.Body.Klarna.SessionOrderLines(
                        type: "mock-type",
                        name: "mock-name",
                        quantity: 1,
                        unitPrice: 100,
                        totalAmount: 100,
                        totalDiscountAmount: 0)
                ],
                billingAddress: Response.Body.Klarna.BillingAddress(
                    addressLine1: "Mock address line 1",
                    addressLine2: "Mock address line 2",
                    addressLine3: "Mock address line 3",
                    city: "London",
                    countryCode: "GB",
                    email: "john@primer.io",
                    firstName: "John",
                    lastName: "Smith",
                    phoneNumber: "+447812345678",
                    postalCode: "PC123456",
                    state: "Greater London",
                    title: "Mock title"),
                tokenDetails: Response.Body.Klarna.TokenDetails(
                    brand: "Visa",
                    maskedNumber: "**** **** **** 1234",
                    type: "Visa",
                    expiryDate: "03/2030")))
        static let mockPollingResults: [(PollingResponse?, Error?)] = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]
        static let mockTokenizePaymentMethod = PrimerPaymentMethodTokenData(
            analyticsId: "mock_analytics_id",
            id: "mock_payment_method_token_data_id",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .unknown,
            paymentMethodType: "MOCK_WEB_REDIRECT_PAYMENT_METHOD",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "mock_payment_method_token",
            tokenType: .singleUse,
            vaultData: nil)
        static let mockExchangePaymentMethodToken = MockPrimerAPIClient.Samples.mockTokenizePaymentMethod
        static let mockBegin3DSAuth = ThreeDS.BeginAuthResponse(
            authentication: ThreeDS.Authentication(
                acsReferenceNumber: nil,
                acsSignedContent: nil,
                acsTransactionId: nil,
                responseCode: .authSuccess,
                transactionId: nil,
                acsOperatorId: nil,
                cryptogram: nil,
                dsReferenceNumber: nil,
                dsTransactionId: nil,
                eci: nil,
                protocolVersion: "2.1.0",
                xid: nil),
            token: PrimerPaymentMethodTokenData(
                analyticsId: "mock_analytics_id",
                id: "mock_payment_method_token_data_id",
                isVaulted: false,
                isAlreadyVaulted: false,
                paymentInstrumentType: .unknown,
                paymentMethodType: "MOCK_WEB_REDIRECT_PAYMENT_METHOD",
                paymentInstrumentData: nil,
                threeDSecureAuthentication: nil,
                token: "mock_payment_method_token",
                tokenType: .singleUse,
                vaultData: nil),
            resumeToken: "mock-resume-token")
        static let mockContinue3DSAuth = ThreeDS.PostAuthResponse(
            token: MockPrimerAPIClient.Samples.mockTokenizePaymentMethod,
            resumeToken: "mock-resume-token",
            authentication: nil)
        static let mockApayaSessionResult = Response.Body.Apaya.CreateSession(
            url: "https://primer.io/apaya",
            token: "mock-token",
            passthroughVariable: nil)
        static let mockAdyenBanks = [
            Response.Body.Adyen.Bank(
                id: "mock-bank-id",
                name: "mock-bank-name",
                iconUrlStr: "https://primer.io/bank-logo",
                disabled: false)
        ]
        static let mockListRetailOutlets = RetailOutletsList(
            result: [
                RetailOutletsRetail(
                    id: "mock-retail-id",
                    name: "mock-retail-name",
                    iconUrl: URL(string: "https://primer.io/mock-retail-icon")!,
                    disabled: false)
            ])
        static let mockPayment = Response.Body.Payment(
            id: "mock_id",
            paymentId: "mock_payment_id",
            amount: 1000,
            currencyCode: "EUR",
            customer: nil,
            customerId: "mock_customer_id",
            dateStr: nil,
            order: nil,
            orderId: nil,
            requiredAction: nil,
            status: .success,
            paymentFailureReason: nil)
        static let mockSendAnalyticsEvents = Analytics.Service.Response(
            id: "mock-id",
            result: "success")
        static let mockFetchPayPalExternalPayerInfo = Response.Body.PayPal.PayerInfo(
            orderId: "mock-order-id",
            externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo(
                externalPayerId: "mock-id",
                email: "john@email.com",
                firstName: "John",
                lastName: "Smith"
            ))
        static let mockResumePayment = Response.Body.Payment(
            id: "mock_id",
            paymentId: "mock_payment_id",
            amount: 1000,
            currencyCode: "EUR",
            customer: nil,
            customerId: "mock_customer_id",
            dateStr: nil,
            order: nil,
            orderId: nil,
            requiredAction: nil,
            status: .success,
            paymentFailureReason: nil)
        
        static let mockFetchNolSdkSecret = Response.Body.NolPay.NolPaySecretDataResponse(sdkSecret: "")

    }
}
