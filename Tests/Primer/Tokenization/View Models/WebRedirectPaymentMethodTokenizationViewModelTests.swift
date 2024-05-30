//
//  WebRedirectPaymentMethodTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 22/05/2024.
//

import XCTest
@testable import PrimerSDK

final class WebRedirectPaymentMethodTokenizationViewModelTests: XCTestCase {

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var uiManager: MockPrimerUIManager!

    var sut: WebRedirectPaymentMethodTokenizationViewModel!

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        sut = WebRedirectPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.webRedirectPaymentMethod,
                                                            uiManager: uiManager,
                                                            tokenizationService: tokenizationService,
                                                            createResumePaymentService: createResumePaymentService)
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    func testClientTokenValidation() throws {
        SDKSessionHelper.tearDown()
        XCTAssertThrowsError(try sut.validate())

        try SDKSessionHelper.test {
            XCTAssertNoThrow(try sut.validate())
        }
    }

    func testStartWithCancellation() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        sut.start()

        let expectDidFail = self.expectation(description: "onDidFail called")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.cancelled(let paymentMethodType, _, _):
                XCTAssertEqual(paymentMethodType, Mocks.Static.Strings.webRedirectPaymentMethodType)
            default:
                XCTFail()
            }
            expectDidFail.fulfill()
        }

        let cancelNotif = Notification(name: Notification.Name.receivedUrlSchemeCancellation)
        NotificationCenter.default.post(cancelNotif)

        waitForExpectations(timeout: 2.0)
    }

    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.abortPaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectWillAbort = self.expectation(description: "onDidAbort is called")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError:
                break
            default:
                XCTFail()
            }
            expectWillAbort.fulfill()
        }

        sut.start()

        waitForExpectations(timeout: 2.0)
    }

    func testStartWithFullCheckoutFlow() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        PollingModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "4321", source: "src"), nil)
        ]

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectDidStartTokenization = self.expectation(description: "onDidStartTokenization is called")
        delegate.onDidStartTokenization = { type in
            XCTAssertEqual(type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            expectDidStartTokenization.fulfill()
        }

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { body in
            expectDidTokenize.fulfill()
            return Promise.fulfilled(.init(analyticsId: "analytics_id",
                                           id: "id",
                                           isVaulted: false,
                                           isAlreadyVaulted: false,
                                           paymentInstrumentType: .offSession,
                                           paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
                                           paymentInstrumentData: nil,
                                           threeDSecureAuthentication: nil,
                                           token: "token",
                                           tokenType: .singleUse,
                                           vaultData: nil))
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { body in
            expectDidCreatePayment.fulfill()
            return .init(id: "id",
                         paymentId: "payment_id",
                         amount: 123,
                         currencyCode: "GBP",
                         customer: nil,
                         customerId: "customer_id",
                         dateStr: nil,
                         order: nil,
                         orderId: "order_id",
                         requiredAction: .init(clientToken: MockAppState.mockClientTokenWithRedirect,
                                               name: .checkout,
                                               description: "description"),
                         status: .success,
                         paymentFailureReason: nil)
        }

        let expectDidShowPaymentMethod = self.expectation(description: "Payment method was shown in web view")
        uiDelegate.onUIDidShowPaymentMethod = { type in
            XCTAssertNotNil(self.sut.webViewController?.delegate)
            expectDidShowPaymentMethod.fulfill()
        }

        let expectResumePayment = self.expectation(description: "Resumed payment")
        createResumePaymentService.onResumePayment = { paymentId, request in
            XCTAssertEqual(paymentId, "id")
            XCTAssertEqual(request.resumeToken, "4321")
            expectResumePayment.fulfill()
            return .init(id: "id",
                         paymentId: "payment_id",
                         amount: 1234,
                         currencyCode: "GBP",
                         customer: nil,
                         customerId: "customer_id", 
                         dateStr: nil,
                         order: nil,
                         orderId: "order_id",
                         requiredAction: nil, 
                         status: .success,
                         paymentFailureReason: nil)
        }

        let expectCheckoutDidCompletewithData = self.expectation(description: "")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectCheckoutDidCompletewithData.fulfill()
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectDidStartTokenization,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidShowPaymentMethod,
            expectResumePayment,
            expectCheckoutDidCompletewithData
        ], enforceOrder: true)
    }


}
