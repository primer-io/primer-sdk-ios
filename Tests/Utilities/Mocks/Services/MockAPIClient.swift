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
    var mockedNetworkDelay: TimeInterval = 0.5
    var validateClientTokenResult: (SuccessResponse?, Error?)?
    var fetchConfigurationResult: (Response.Body.Configuration?, Error?)?
    var fetchConfigurationWithActionsResult: (Response.Body.Configuration?, Error?)?
    var fetchVaultedPaymentMethodsResult: (Response.Body.VaultedPaymentMethods?, Error?)?
    var deleteVaultedPaymentMethodResult: (Void?, Error?)?
    var createPayPalOrderSessionResult: (Response.Body.PayPal.CreateOrder?, Error?)?
    var createPayPalBillingAgreementSessionResult: (Response.Body.PayPal.CreateBillingAgreement?, Error?)?
    var confirmPayPalBillingAgreementResult: (Response.Body.PayPal.ConfirmBillingAgreement?, Error?)?
    var createKlarnaPaymentSessionResult: (Response.Body.Klarna.PaymentSession?, Error?)?
    var createKlarnaCustomerTokenResult: (Response.Body.Klarna.CustomerToken?, Error?)?
    var finalizeKlarnaPaymentSessionResult: (Response.Body.Klarna.CustomerToken?, Error?)?
    var pollingResults: [(PollingResponse?, Error?)]?
    var tokenizePaymentMethodResult: (PrimerPaymentMethodTokenData?, Error?)?
    var exchangePaymentMethodTokenResult: (PrimerPaymentMethodTokenData?, Error?)?
    var begin3DSAuthResult: (ThreeDS.BeginAuthResponse?, Error?)?
    var continue3DSAuthResult: (ThreeDS.PostAuthResponse?, Error?)?
    var listAdyenBanksResult: (BanksListSessionResponse?, Error?)?
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
    var sdkCompleteUrlResult: (Response.Body.Complete?, Error?)?
    var responseHeaders: [String: String]?

    func validateClientToken(
        request _: Request.Body.ClientTokenValidation,
        completion: @escaping (_ result: Result<SuccessResponse, Error>) -> Void
    ) {
        guard let result = validateClientTokenResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'validateClientTokenResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func validateClientToken(request _: Request.Body.ClientTokenValidation) async throws -> SuccessResponse {
        guard let (successResult, errorResult) = validateClientTokenResult else {
            XCTAssert(false, "Set 'validateClientTokenResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = errorResult {
            throw errorResult
        } else if let successResult = successResult {
            return successResult
        } else {
            XCTAssert(false, "Set 'validateClientTokenResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func fetchConfiguration(clientToken _: PrimerSDK.DecodedJWTToken,
                            requestParameters _: PrimerSDK.Request.URLParameters.Configuration?,
                            completion: @escaping PrimerSDK.ConfigurationCompletion) {
        guard let result = fetchConfigurationResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchConfigurationResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err), nil)
            } else if let successResult = result.0 {
                completion(.success(successResult), self.responseHeaders ?? [:])
            }
        }
    }

    func fetchConfiguration(clientToken _: DecodedJWTToken,
                            requestParameters _: Request.URLParameters.Configuration?) async throws -> (PrimerAPIConfiguration, [String: String]?) {
        guard let (successResult, errorResult) = fetchConfigurationResult else {
            XCTAssert(false, "Set 'fetchConfigurationResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = errorResult {
            throw errorResult
        } else if let successResult = successResult {
            return (successResult, responseHeaders ?? [:])
        } else {
            XCTAssert(false, "Set 'fetchConfigurationResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func fetchVaultedPaymentMethods(
        clientToken _: DecodedJWTToken,
        completion: @escaping (_ result: Result<Response.Body.VaultedPaymentMethods, Error>) -> Void
    ) {
        guard let result = fetchVaultedPaymentMethodsResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchVaultedPaymentMethodsResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
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
        clientToken _: DecodedJWTToken,
        id _: String,
        completion: @escaping (_ result: Result<Void, Error>) -> Void
    ) {
        guard let result = deleteVaultedPaymentMethodResult else {
            XCTAssert(false, "Set 'deleteVaultedPaymentMethodResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else {
                completion(.success(()))
            }
        }
    }

    // PayPal
    func createPayPalOrderSession(
        clientToken _: DecodedJWTToken,
        payPalCreateOrderRequest _: Request.Body.PayPal.CreateOrder,
        completion: @escaping (_ result: Result<Response.Body.PayPal.CreateOrder, Error>) -> Void
    ) {
        guard let result = createPayPalOrderSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createPayPalOrderSessionResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func createPayPalBillingAgreementSession(
        clientToken _: DecodedJWTToken,
        payPalCreateBillingAgreementRequest _: Request.Body.PayPal.CreateBillingAgreement,
        completion: @escaping (_ result: Result<Response.Body.PayPal.CreateBillingAgreement, Error>) -> Void
    ) {
        guard let result = createPayPalBillingAgreementSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createPayPalBillingAgreementSessionResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func confirmPayPalBillingAgreement(
        clientToken _: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest _: Request.Body.PayPal.ConfirmBillingAgreement,
        completion: @escaping (_ result: Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void
    ) {
        guard let result = confirmPayPalBillingAgreementResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'confirmPayPalBillingAgreementResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    // Klarna
    func createKlarnaPaymentSession(
        clientToken _: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest _: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping (_ result: Result<Response.Body.Klarna.PaymentSession, Error>) -> Void
    ) {
        guard let result = createKlarnaPaymentSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func createKlarnaPaymentSession(
        clientToken _: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest _: Request.Body.Klarna.CreatePaymentSession
    ) async throws -> Response.Body.Klarna.PaymentSession {
        guard let result = createKlarnaPaymentSessionResult else {
            XCTAssert(false, "Set 'createKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'createKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func createKlarnaCustomerToken(
        clientToken _: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest _: Request.Body.Klarna.CreateCustomerToken,
        completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    ) {
        guard let result = createKlarnaCustomerTokenResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'createKlarnaCustomerTokenResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func createKlarnaCustomerToken(
        clientToken _: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest _: Request.Body.Klarna.CreateCustomerToken
    ) async throws -> Response.Body.Klarna.CustomerToken {
        guard let result = createKlarnaCustomerTokenResult else {
            XCTAssert(false, "Set 'createKlarnaCustomerTokenResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'createKlarnaCustomerTokenResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func finalizeKlarnaPaymentSession(
        clientToken _: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest _: Request.Body.Klarna.FinalizePaymentSession,
        completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    ) {
        guard let result = finalizeKlarnaPaymentSessionResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'finalizeKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func finalizeKlarnaPaymentSession(
        clientToken _: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest _: Request.Body.Klarna.FinalizePaymentSession
    ) async throws -> Response.Body.Klarna.CustomerToken {
        guard let result = finalizeKlarnaPaymentSessionResult else {
            XCTAssert(false, "Set 'finalizeKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'finalizeKlarnaPaymentSessionResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    // Tokenization
    func tokenizePaymentMethod(
        clientToken _: DecodedJWTToken,
        tokenizationRequestBody _: Request.Body.Tokenization,
        completion: @escaping (_ result: Result<PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        guard let result = tokenizePaymentMethodResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'tokenizePaymentMethodResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func tokenizePaymentMethod(clientToken _: DecodedJWTToken,
                               tokenizationRequestBody _: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        guard let result = tokenizePaymentMethodResult else {
            XCTAssert(false, "Set 'tokenizePaymentMethodResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'tokenizePaymentMethodResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func exchangePaymentMethodToken(
        clientToken _: PrimerSDK.DecodedJWTToken,
        vaultedPaymentMethodId _: String,
        vaultedPaymentMethodAdditionalData _: PrimerSDK.PrimerVaultedPaymentMethodAdditionalData?,
        completion: @escaping (Result<PrimerSDK.PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        guard let result = exchangePaymentMethodTokenResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'tokenizePaymentMethodResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func exchangePaymentMethodToken(
        clientToken _: DecodedJWTToken,
        vaultedPaymentMethodId _: String,
        vaultedPaymentMethodAdditionalData _: (any PrimerVaultedPaymentMethodAdditionalData)?
    ) async throws -> PrimerPaymentMethodTokenData {
        guard let result = exchangePaymentMethodTokenResult else {
            XCTAssert(false, "Set 'exchangePaymentMethodTokenResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'exchangePaymentMethodTokenResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    // 3DS
    func begin3DSAuth(
        clientToken _: DecodedJWTToken,
        paymentMethodTokenData _: PrimerPaymentMethodTokenData,
        threeDSecureBeginAuthRequest _: ThreeDS.BeginAuthRequest,
        completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void
    ) {
        guard let result = begin3DSAuthResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'begin3DSAuthResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func begin3DSAuth(
        clientToken _: DecodedJWTToken,
        paymentMethodTokenData _: PrimerPaymentMethodTokenData,
        threeDSecureBeginAuthRequest _: ThreeDS.BeginAuthRequest
    ) async throws -> ThreeDS.BeginAuthResponse {
        guard let result = begin3DSAuthResult else {
            XCTAssert(false, "Set 'begin3DSAuthResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'begin3DSAuthResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func continue3DSAuth(
        clientToken _: PrimerSDK.DecodedJWTToken,
        threeDSTokenId _: String,
        continueInfo _: PrimerSDK.ThreeDS.ContinueInfo,
        completion: @escaping (Result<PrimerSDK.ThreeDS.PostAuthResponse, Error>) -> Void
    ) {
        guard let result = continue3DSAuthResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'continue3DSAuthResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func continue3DSAuth(clientToken _: DecodedJWTToken, threeDSTokenId _: String, continueInfo _: ThreeDS.ContinueInfo) async throws -> ThreeDS
        .PostAuthResponse {
        guard let result = continue3DSAuthResult else {
            XCTAssert(false, "Set 'continue3DSAuthResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'continue3DSAuthResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func listAdyenBanks(
        clientToken _: DecodedJWTToken,
        request _: Request.Body.Adyen.BanksList,
        completion: @escaping APICompletion<PrimerSDK.BanksListSessionResponse>
    ) {
        guard let result = listAdyenBanksResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'listAdyenBanksResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func listRetailOutlets(
        clientToken _: PrimerSDK.DecodedJWTToken,
        paymentMethodId _: String,
        completion: @escaping (Result<PrimerSDK.RetailOutletsList, Error>) -> Void
    ) {
        guard let result = listRetailOutletsResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'listRetailOutletsResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
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
        completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void
    ) {
        guard let pollingResults = pollingResults,
              !pollingResults.isEmpty
        else {
            XCTAssert(false, "Set 'pollingResults' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
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

    func poll(clientToken _: DecodedJWTToken?, url _: String) async throws -> PollingResponse {
        guard let pollingResults = pollingResults,
              !pollingResults.isEmpty
        else {
            XCTAssert(false, "Set 'pollingResults' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        let pollingResult = pollingResults[currentPollingIteration]
        currentPollingIteration += 1

        if pollingResult.0 == nil && pollingResult.1 == nil {
            XCTAssert(false, "Each 'pollingResult' must have a response or an error.")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        if let err = pollingResult.1 {
            if currentPollingIteration == pollingResults.count {
                XCTAssert(false, "Polling finished with error")
                throw err
            } else {
                return try await poll(clientToken: nil, url: "")
            }
        } else if let res = pollingResult.0 {
            if res.status == .complete {
                return res
            } else {
                return try await poll(clientToken: nil, url: "")
            }
        }

        XCTAssert(false, "Polling finished with error")
        throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
    }

    func requestPrimerConfigurationWithActions(
        clientToken _: DecodedJWTToken,
        request _: ClientSessionUpdateRequest,
        completion: @escaping PrimerSDK.ConfigurationCompletion
    ) {
        guard let result = fetchConfigurationWithActionsResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchConfigurationWithActionsResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err), nil)
            } else if let successResult = result.0 {
                completion(.success(successResult), self.responseHeaders ?? [:])
            }
        }
    }

    func requestPrimerConfigurationWithActions(clientToken _: DecodedJWTToken,
                                               request _: ClientSessionUpdateRequest) async throws -> (PrimerAPIConfiguration, [String: String]?) {
        guard let (successResult, errorResult) = fetchConfigurationWithActionsResult else {
            XCTAssert(false, "Set 'fetchConfigurationWithActionsResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = errorResult {
            throw errorResult
        } else if let successResult = successResult {
            return (successResult, responseHeaders ?? [:])
        } else {
            XCTAssert(false, "Set 'fetchConfigurationWithActionsResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func sendAnalyticsEvents(
        clientToken _: DecodedJWTToken?,
        url _: URL,
        body _: [Analytics.Event]?,
        completion: @escaping (Result<Analytics.Service.Response, Error>) -> Void
    ) {
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
        clientToken _: DecodedJWTToken,
        payPalExternalPayerInfoRequestBody _: Request.Body.PayPal.PayerInfo,
        completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void
    ) {
        guard let result = fetchPayPalExternalPayerInfoResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'fetchPayPalExternalPayerInfoResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    // Payment
    func createPayment(
        clientToken _: DecodedJWTToken,
        paymentRequestBody _: Request.Body.Payment.Create,
        completion: @escaping (_ result: Result<Response.Body.Payment, Error>) -> Void
    ) {
        guard let result = paymentResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'paymentResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func createPayment(clientToken _: DecodedJWTToken,
                       paymentRequestBody _: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        guard let result = paymentResult else {
            XCTAssert(false, "Set 'paymentResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'paymentResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func resumePayment(
        clientToken _: DecodedJWTToken,
        paymentId _: String,
        paymentResumeRequest _: Request.Body.Payment.Resume,
        completion: @escaping (Result<Response.Body.Payment, Error>) -> Void
    ) {
        guard let result = resumePaymentResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'resumePaymentResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func resumePayment(clientToken _: DecodedJWTToken,
                       paymentId _: String,
                       paymentResumeRequest _: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        guard let result = resumePaymentResult else {
            XCTAssert(false, "Set 'resumePaymentResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'resumePaymentResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func testFinalizePolling(clientToken _: PrimerSDK.DecodedJWTToken, testId _: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let result = testFinalizePollingResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'testFinalizePollingResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else {
                completion(.success(()))
            }
        }
    }

    func testFinalizePolling(clientToken _: DecodedJWTToken, testId _: String) async throws {
        guard let result = testFinalizePollingResult else {
            XCTAssert(false, "Set 'testFinalizePollingResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else {
            return
        }
    }

    func listCardNetworks(clientToken _: DecodedJWTToken, bin _: String,
                          completion: @escaping (Result<Response.Body.Bin.Networks, Error>) -> Void) -> PrimerCancellable? {
        guard let result = listCardNetworksResult, result.0 != nil || result.1 != nil else {
            XCTFail("Set 'listCardNetworksResult' on your MockPrimerAPIClient")
            return nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let res = result.0 {
                completion(.success(res))
            }
        }

        return nil
    }

    func listCardNetworks(clientToken _: DecodedJWTToken, bin _: String) async throws -> Response.Body.Bin.Networks {
        guard let result = listCardNetworksResult else {
            XCTFail("Set 'listCardNetworksResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTFail("Set 'listCardNetworksResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func fetchNolSdkSecret(
        clientToken _: PrimerSDK.DecodedJWTToken,
        paymentRequestBody _: PrimerSDK.Request.Body.NolPay.NolPaySecretDataRequest,
        completion: @escaping (Result<PrimerSDK.Response.Body.NolPay.NolPaySecretDataResponse, Error>) -> Void
    ) {
        guard let result = testFetchNolSdkSecretResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'testFetchNolSdkSecretResult' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func fetchNolSdkSecret(clientToken _: DecodedJWTToken, paymentRequestBody _: Request.Body.NolPay.NolPaySecretDataRequest) async throws -> Response
        .Body.NolPay.NolPaySecretDataResponse {
        guard let result = testFetchNolSdkSecretResult else {
            XCTAssert(false, "Set 'testFetchNolSdkSecretResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'testFetchNolSdkSecretResult' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func genericAPICall(clientToken _: PrimerSDK.DecodedJWTToken, url _: URL, completion: @escaping (Result<Bool, Error>) -> Void) {
        Timer.scheduledTimer(withTimeInterval: mockedNetworkDelay, repeats: false) { _ in
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }
    }

    func genericAPICall(clientToken _: DecodedJWTToken, url _: URL) async throws -> Bool {
        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        return true
    }

    func getPhoneMetadata(
        clientToken _: PrimerSDK.DecodedJWTToken,
        paymentRequestBody _: PrimerSDK.Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
        completion: @escaping (Result<PrimerSDK.Response.Body.PhoneMetadata.PhoneMetadataDataResponse, Error>) -> Void
    ) {
        completion(.success(phoneMetadataResult))
    }

    func getPhoneMetadata(clientToken _: DecodedJWTToken,
                          paymentRequestBody _: Request.Body.PhoneMetadata.PhoneMetadataDataRequest) async throws -> Response.Body.PhoneMetadata
        .PhoneMetadataDataResponse {
        return phoneMetadataResult
    }

    func completePayment(
        clientToken _: PrimerSDK.DecodedJWTToken,
        url _: URL,
        paymentRequest _: PrimerSDK.Request.Body.Payment.Complete,
        completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.Complete>
    ) {
        guard let result = sdkCompleteUrlResult,
              result.0 != nil || result.1 != nil
        else {
            XCTAssert(false, "Set 'completePayment' on your MockPrimerAPIClient")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let err = result.1 {
                completion(.failure(err))
            } else if let successResult = result.0 {
                completion(.success(successResult))
            }
        }
    }

    func completePayment(clientToken _: PrimerSDK.DecodedJWTToken,
                         url _: URL,
                         paymentRequest _: PrimerSDK.Request.Body.Payment.Complete) async throws -> PrimerSDK.Response.Body.Complete {
        guard let result = sdkCompleteUrlResult else {
            XCTAssert(false, "Set 'completePayment' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let errorResult = result.1 {
            throw errorResult
        } else if let successResult = result.0 {
            return successResult
        } else {
            XCTAssert(false, "Set 'completePayment' on your MockPrimerAPIClient")
            throw NSError(domain: "MockPrimerAPIClient", code: 1, userInfo: nil)
        }
    }

    func mockSuccessfulResponses() {
        validateClientTokenResult = (MockPrimerAPIClient.Samples.mockValidateClientToken, nil)
        fetchConfigurationResult = (MockPrimerAPIClient.Samples.mockPrimerAPIConfiguration, nil)
        fetchVaultedPaymentMethodsResult = (MockPrimerAPIClient.Samples.mockVaultedPaymentMethods, nil)
        createPayPalOrderSessionResult = (MockPrimerAPIClient.Samples.mockPayPalCreateOrder, nil)
        createPayPalBillingAgreementSessionResult = (MockPrimerAPIClient.Samples.mockCreatePayPalBillingAgreementSession, nil)
        confirmPayPalBillingAgreementResult = (MockPrimerAPIClient.Samples.mockConfirmPayPalBillingAgreement, nil)
        createKlarnaPaymentSessionResult = (MockPrimerAPIClient.Samples.mockCreateKlarnaPaymentSession, nil)
        createKlarnaCustomerTokenResult = (MockPrimerAPIClient.Samples.mockCreateKlarnaCustomerToken, nil)
        finalizeKlarnaPaymentSessionResult = (MockPrimerAPIClient.Samples.mockFinalizeKlarnaPaymentSession, nil)
        pollingResults = MockPrimerAPIClient.Samples.mockPollingResults
        tokenizePaymentMethodResult = (MockPrimerAPIClient.Samples.mockTokenizePaymentMethod, nil)
        exchangePaymentMethodTokenResult = (MockPrimerAPIClient.Samples.mockExchangePaymentMethodToken, nil)
        begin3DSAuthResult = (MockPrimerAPIClient.Samples.mockBegin3DSAuth, nil)
        continue3DSAuthResult = (MockPrimerAPIClient.Samples.mockContinue3DSAuth, nil)
        listAdyenBanksResult = (MockPrimerAPIClient.Samples.mockAdyenBanks, nil)
        listRetailOutletsResult = (MockPrimerAPIClient.Samples.mockListRetailOutlets, nil)
        paymentResult = (MockPrimerAPIClient.Samples.mockPayment, nil)
        resumePaymentResult = (MockPrimerAPIClient.Samples.mockResumePayment, nil)
        sendAnalyticsEventsResult = (MockPrimerAPIClient.Samples.mockSendAnalyticsEvents, nil)
        fetchPayPalExternalPayerInfoResult = (MockPrimerAPIClient.Samples.mockFetchPayPalExternalPayerInfo, nil)
        testFetchNolSdkSecretResult = (MockPrimerAPIClient.Samples.mockFetchNolSdkSecret, nil)
        sdkCompleteUrlResult = (MockPrimerAPIClient.Samples.mockSdkCompleteUrl, nil)
    }
}

extension MockPrimerAPIClient {
    class Samples {
        static let mockValidateClientToken: SuccessResponse = .init()
        static let mockPrimerAPIConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            binDataUrl: "https://primer.io/bindata",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: ClientSession.APIResponse(
                clientSessionId: "mock-client-session-id-1",
                paymentMethod: ClientSession.PaymentMethod(
                    vaultOnSuccess: false,
                    options: nil,
                    orderedAllowedCardNetworks: nil
                ),
                order: ClientSession.Order(
                    id: "mock-client-session-order-id-1",
                    merchantAmount: nil,
                    totalOrderAmount: 100,
                    totalTaxAmount: nil,
                    countryCode: .gb,
                    currencyCode: CurrencyLoader().getCurrency("GBP"),
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
                            taxCode: nil,
                            productType: nil
                        ),
                    ]
                ),
                customer: nil,
                testId: nil
            ),
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "mock-id-1",
                    implementationType: .webRedirect,
                    type: "ADYEN_GIROPAY",
                    name: "Giropay",
                    processorConfigId: "mock-processor-config-id-1",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil
                ),
                PrimerPaymentMethod(
                    id: "mock-id-2",
                    implementationType: .webRedirect,
                    type: "ADYEN_DOTPAY",
                    name: "Payment Method Unavailable on Headless",
                    processorConfigId: "mock-processor-config-id-2",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil
                ),
            ],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil
        )
        static let mockVaultedPaymentMethods = Response.Body.VaultedPaymentMethods(
            data: []
        )
        static let mockPayPalCreateOrder: Response.Body.PayPal.CreateOrder = .init(
            orderId: "mock-id",
            approvalUrl: "https://primer.io/approval"
        )
        static let mockCreatePayPalBillingAgreementSession = Response.Body.PayPal.CreateBillingAgreement(
            tokenId: "mock_token-id",
            approvalUrl: "https://primer.io/approval"
        )
        static let mockConfirmPayPalBillingAgreement = Response.Body.PayPal.ConfirmBillingAgreement(
            billingAgreementId: "mock-paypal-billing-agreement-id",
            externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo(
                externalPayerId: "mock-external-payer-id",
                email: "john@email.com",
                firstName: "John",
                lastName: "Smith"
            ),
            shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress(
                firstName: "John",
                lastName: "Smith",
                addressLine1: "Mock address line 1",
                addressLine2: "Mock address line 2",
                city: "London",
                state: "London Greater Area",
                countryCode: "GB",
                postalCode: "PC12345"
            )
        )
        static let mockCreateKlarnaPaymentSession = Response.Body.Klarna.PaymentSession(
            clientToken: "mock-client-token",
            sessionId: "mock-session-id",
            categories: [
                Response.Body.Klarna.SessionCategory(
                    identifier: "mock-session-category-id",
                    name: "mock-session-category-name",
                    descriptiveAssetUrl: "https://klarna.com/assets-descriptive",
                    standardAssetUrl: "https://klarna.com/assets-standard"
                ),
            ],
            hppSessionId: "mock-hpp-session-id",
            hppRedirectUrl: "https://klarna.com/redirect"
        )
        static let mockCreateKlarnaCustomerToken = Response.Body.Klarna.CustomerToken(
            customerTokenId: "mock-customer-token-id",
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: "Mock recurring description",
                purchaseCountry: "SE",
                purchaseCurrency: "SEK",
                locale: "en-US",
                orderAmount: 100,
                orderTaxAmount: nil,
                orderLines: [
                    Response.Body.Klarna.SessionOrderLines(
                        type: "mock-type",
                        name: "mock-name",
                        quantity: 1,
                        unitPrice: 100,
                        totalAmount: 100,
                        totalDiscountAmount: 0
                    ),
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
                    title: "Mock title"
                ),
                shippingAddress: nil,
                tokenDetails: Response.Body.Klarna.TokenDetails(
                    brand: "Visa",
                    maskedNumber: "**** **** **** 1234",
                    type: "Visa",
                    expiryDate: "03/2030"
                )
            )
        )
        static let mockFinalizeKlarnaPaymentSession = Response.Body.Klarna.CustomerToken(
            customerTokenId: "mock-customer-token-id",
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: "Mock recurring description",
                purchaseCountry: "SE",
                purchaseCurrency: "SEK",
                locale: "en-US",
                orderAmount: 100,
                orderTaxAmount: nil,
                orderLines: [
                    Response.Body.Klarna.SessionOrderLines(
                        type: "mock-type",
                        name: "mock-name",
                        quantity: 1,
                        unitPrice: 100,
                        totalAmount: 100,
                        totalDiscountAmount: 0
                    ),
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
                    title: "Mock title"
                ),
                shippingAddress: nil,
                tokenDetails: Response.Body.Klarna.TokenDetails(
                    brand: "Visa",
                    maskedNumber: "**** **** **** 1234",
                    type: "Visa",
                    expiryDate: "03/2030"
                )
            )
        )
        static let mockPollingResults: [(PollingResponse?, Error?)] = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil),
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
            vaultData: nil
        )
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
                xid: nil
            ),
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
                vaultData: nil
            ),
            resumeToken: "mock-resume-token"
        )
        static let mockContinue3DSAuth = ThreeDS.PostAuthResponse(
            token: MockPrimerAPIClient.Samples.mockTokenizePaymentMethod,
            resumeToken: "mock-resume-token",
            authentication: nil
        )
        static let mockAdyenBanks = BanksListSessionResponse(
            result: [
                Response.Body.Adyen.Bank(
                    id: "mock-bank-id",
                    name: "mock-bank-name",
                    iconUrlStr: "https://primer.io/bank-logo",
                    disabled: false
                ),
            ]
        )
        static let mockListRetailOutlets = RetailOutletsList(
            result: [
                RetailOutletsRetail(
                    id: "mock-retail-id",
                    name: "mock-retail-name",
                    iconUrl: URL(string: "https://primer.io/mock-retail-icon")!,
                    disabled: false
                ),
            ]
        )
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
            paymentFailureReason: nil
        )
        static let mockSendAnalyticsEvents = Analytics.Service.Response(
            id: "mock-id",
            result: "success"
        )
        static let mockFetchPayPalExternalPayerInfo = Response.Body.PayPal.PayerInfo(
            orderId: "mock-order-id",
            externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo(
                externalPayerId: "mock-id",
                email: "john@email.com",
                firstName: "John",
                lastName: "Smith"
            )
        )
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
            paymentFailureReason: nil
        )

        static let mockFetchNolSdkSecret = Response.Body.NolPay.NolPaySecretDataResponse(sdkSecret: "")
        static let mockSdkCompleteUrl = Response.Body.Complete()
    }
}
