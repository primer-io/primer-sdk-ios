//
//  File.swift
//  
//
//  Created by Niall Quinn on 01/08/24.
//

import XCTest
@testable import PrimerSDK

final class CreateResumePaymentServiceTests: XCTestCase {

    typealias Payment = Response.Body.Payment

    func test_createNoJWT() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = nil
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createSuccess() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createFailure() throws {
        let response = Payment.failedStatusResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPending() throws {
        let response = Payment.pendingStatusResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createError() throws {
        let response = Payment.errorResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }


    func test_resumeNoJWT() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = nil
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumeSuccess() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumeFailure() throws {
        let response = Payment.failedStatusResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePending() throws {
        let response = Payment.pendingStatusResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumeError() throws {
        let response = Payment.errorResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePending_showSuccessCheckoutOnPendingPayment() throws {
        let response = Payment.pendingStatusResponseWithShowCheckoutSuccessOnPending
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Failed, but flag should result in success")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

}


private class MockCreateResumeAPI: PrimerAPIClientProtocol {

    var resumeResponse: APIResult<Response.Body.Payment>?
    var createResponse: APIResult<Response.Body.Payment>?

    init(resumeResponse: APIResult<Response.Body.Payment>? = nil, createResponse: APIResult<Response.Body.Payment>? = nil) {
        self.resumeResponse = resumeResponse
        self.createResponse = createResponse
    }

    func createPayment(clientToken: DecodedJWTToken, paymentRequestBody: Request.Body.Payment.Create, completion: @escaping APICompletion<Response.Body.Payment>) {
        guard let createResponse else {
            XCTFail("No create response set")
            return
        }
        completion(createResponse)
    }

    func resumePayment(clientToken: DecodedJWTToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping APICompletion<Response.Body.Payment>) {
        guard let resumeResponse else {
            XCTFail("No resume response set")
            return
        }
        completion(resumeResponse)
    }
}

private extension Response.Body.Payment {
    static var successResponse: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .success,
                       paymentFailureReason: nil))
    }

    static var failedStatusResponse: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .failed,
                       paymentFailureReason: nil))
    }

    static var pendingStatusResponse: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .pending,
                       paymentFailureReason: nil))
    }

    static var pendingStatusResponseWithShowCheckoutSuccessOnPending: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .pending,
                       paymentFailureReason: nil,
                       showSuccessCheckoutOnPendingPayment: true))
    }

    static var errorResponse: APIResult<Response.Body.Payment> {
        .failure(PrimerError.failedToCreatePayment(paymentMethodType: "PAYMENT_CARD",
                                                   description: "",
                                                   userInfo: [:],
                                                   diagnosticsId: ""))
    }
}

//MARK: Unused in these tests
extension MockCreateResumeAPI {
    func fetchConfiguration(clientToken: PrimerSDK.DecodedJWTToken, requestParameters: PrimerSDK.Request.URLParameters.Configuration?, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.Configuration>) {}

    func validateClientToken(request: PrimerSDK.Request.Body.ClientTokenValidation, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.SuccessResponse>) {}

    func requestPrimerConfigurationWithActions(clientToken: PrimerSDK.DecodedJWTToken, request: PrimerSDK.ClientSessionUpdateRequest, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.PrimerAPIConfiguration>) {}

    func createKlarnaPaymentSession(clientToken: PrimerSDK.DecodedJWTToken, klarnaCreatePaymentSessionAPIRequest: PrimerSDK.Request.Body.Klarna.CreatePaymentSession, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.Klarna.PaymentSession>) {}

    func createKlarnaCustomerToken(clientToken: PrimerSDK.DecodedJWTToken, klarnaCreateCustomerTokenAPIRequest: PrimerSDK.Request.Body.Klarna.CreateCustomerToken, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.Klarna.CustomerToken>) {}

    func finalizeKlarnaPaymentSession(clientToken: PrimerSDK.DecodedJWTToken, klarnaFinalizePaymentSessionRequest: PrimerSDK.Request.Body.Klarna.FinalizePaymentSession, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.Klarna.CustomerToken>) {}

    func tokenizePaymentMethod(clientToken: PrimerSDK.DecodedJWTToken, tokenizationRequestBody: PrimerSDK.Request.Body.Tokenization, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.PrimerPaymentMethodTokenData>) {}

    func exchangePaymentMethodToken(clientToken: PrimerSDK.DecodedJWTToken, vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: (any PrimerSDK.PrimerVaultedPaymentMethodAdditionalData)?, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.PrimerPaymentMethodTokenData>) {}

    func begin3DSAuth(clientToken: PrimerSDK.DecodedJWTToken, paymentMethodTokenData: PrimerSDK.PrimerPaymentMethodTokenData, threeDSecureBeginAuthRequest: PrimerSDK.ThreeDS.BeginAuthRequest, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.ThreeDS.BeginAuthResponse>) {}

    func continue3DSAuth(clientToken: PrimerSDK.DecodedJWTToken, threeDSTokenId: String, continueInfo: PrimerSDK.ThreeDS.ContinueInfo, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.ThreeDS.PostAuthResponse>) {}

    func poll(clientToken: PrimerSDK.DecodedJWTToken?, url: String, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.PollingResponse>) {}

    func testFinalizePolling(clientToken: PrimerSDK.DecodedJWTToken, testId: String, completion: @escaping PrimerSDK.APICompletion<Void>) {}

    func genericAPICall(clientToken: PrimerSDK.DecodedJWTToken, url: URL, completion: @escaping PrimerSDK.APICompletion<Bool>) {}

    func fetchNolSdkSecret(clientToken: PrimerSDK.DecodedJWTToken, paymentRequestBody: PrimerSDK.Request.Body.NolPay.NolPaySecretDataRequest, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.NolPay.NolPaySecretDataResponse>) {}

    func getPhoneMetadata(clientToken: PrimerSDK.DecodedJWTToken, paymentRequestBody: PrimerSDK.Request.Body.PhoneMetadata.PhoneMetadataDataRequest, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.PhoneMetadata.PhoneMetadataDataResponse>) {}

    func sendAnalyticsEvents(clientToken: PrimerSDK.DecodedJWTToken?, url: URL, body: [PrimerSDK.Analytics.Event]?, completion: @escaping ResponseHandler) {}

    func listCardNetworks(clientToken: PrimerSDK.DecodedJWTToken, bin: String, completion: @escaping (Result<PrimerSDK.Response.Body.Bin.Networks, any Error>) -> Void) -> (any PrimerSDK.PrimerCancellable)? {
        return nil
    }

    func listAdyenBanks(clientToken: PrimerSDK.DecodedJWTToken, request: PrimerSDK.Request.Body.Adyen.BanksList, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.BanksListSessionResponse>) {}

    func createPayPalOrderSession(clientToken: PrimerSDK.DecodedJWTToken, payPalCreateOrderRequest: PrimerSDK.Request.Body.PayPal.CreateOrder, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.PayPal.CreateOrder>) {}

    func createPayPalBillingAgreementSession(clientToken: PrimerSDK.DecodedJWTToken, payPalCreateBillingAgreementRequest: PrimerSDK.Request.Body.PayPal.CreateBillingAgreement, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.PayPal.CreateBillingAgreement>) {}

    func confirmPayPalBillingAgreement(clientToken: PrimerSDK.DecodedJWTToken, payPalConfirmBillingAgreementRequest: PrimerSDK.Request.Body.PayPal.ConfirmBillingAgreement, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.PayPal.ConfirmBillingAgreement>) {}

    func fetchPayPalExternalPayerInfo(clientToken: PrimerSDK.DecodedJWTToken, payPalExternalPayerInfoRequestBody: PrimerSDK.Request.Body.PayPal.PayerInfo, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.PayPal.PayerInfo>) {}

    func fetchVaultedPaymentMethods(clientToken: PrimerSDK.DecodedJWTToken, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.Response.Body.VaultedPaymentMethods>) {}

    func deleteVaultedPaymentMethod(clientToken: PrimerSDK.DecodedJWTToken, id: String, completion: @escaping PrimerSDK.APICompletion<Void>) {}

    func listRetailOutlets(clientToken: PrimerSDK.DecodedJWTToken, paymentMethodId: String, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.RetailOutletsList>) {}
}
