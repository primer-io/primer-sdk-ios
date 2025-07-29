//
//  WebRedirectPaymentMethodTokenizationViewModelAsyncTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class WebRedirectPaymentMethodTokenizationViewModelAsyncTests: XCTestCase {
    // MARK: - Test Dependencies

    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!
    var uiManager: MockPrimerUIManager!
    var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    var sut: WebRedirectPaymentMethodTokenizationViewModel!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        sut = WebRedirectPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.webRedirectPaymentMethod,
                                                            uiManager: uiManager,
                                                            tokenizationService: tokenizationService,
                                                            createResumePaymentService: createResumePaymentService)

        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    // MARK: - Validation Tests

    func test_validate_withInvalidClientToken_shouldThrowError() throws {
        SDKSessionHelper.tearDown()
        XCTAssertThrowsError(try sut.validate())

        try SDKSessionHelper.test {
            XCTAssertNoThrow(try sut.validate())
        }
    }

    // MARK: - Flow Tests

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentWithData = expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.abortPaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidFail = expectation(description: "flow fails with error")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError:
                break
            default:
                XCTFail()
            }
            expectDidFail.fulfill()
        }

        sut.start_async()

        wait(for: [expectWillCreatePaymentWithData, expectDidFail], timeout: 2.0, enforceOrder: true)
    }

    func test_startFlow_fullCheckout_shouldCompleteSuccessfully() throws {
        SDKSessionHelper.setUp()

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

        let expectWillCreatePaymentWithData = expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidStartTokenization = expectation(description: "tokenization begins")
        delegate.onDidStartTokenization = { type in
            XCTAssertEqual(type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            expectDidStartTokenization.fulfill()
        }

        let expectDidTokenize = expectation(description: "payment method tokenized")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.success(
                PrimerPaymentMethodTokenData(
                    analyticsId: "analytics_id",
                    id: "id",
                    isVaulted: false,
                    isAlreadyVaulted: false,
                    paymentInstrumentType: .offSession,
                    paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
                    paymentInstrumentData: nil,
                    threeDSecureAuthentication: nil,
                    token: "token",
                    tokenType: .singleUse,
                    vaultData: nil
                )
            )
        }

        let expectDidCreatePayment = expectation(description: "payment created")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return Response.Body.Payment(
                id: "id",
                paymentId: "payment_id",
                amount: 123,
                currencyCode: "GBP",
                customerId: "customer_id",
                orderId: "order_id",
                requiredAction: Response.Body.Payment.RequiredAction(
                    clientToken: MockAppState.mockClientTokenWithRedirect,
                    name: .checkout,
                    description: "description"
                ),
                status: .success
            )
        }

        let expectDidShowPaymentMethod = expectation(description: "payment method UI presented")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            XCTAssertNotNil(self.sut.webViewController?.delegate)
            expectDidShowPaymentMethod.fulfill()
        }

        let expectDidResumePayment = expectation(description: "payment resumed")
        createResumePaymentService.onResumePayment = { paymentId, request in
            XCTAssertEqual(paymentId, "id")
            XCTAssertEqual(request.resumeToken, "4321")
            expectDidResumePayment.fulfill()
            return Response.Body.Payment(
                id: "id",
                paymentId: "payment_id",
                amount: 1234,
                currencyCode: "GBP",
                customerId: "customer_id",
                orderId: "order_id",
                status: .success
            )
        }

        let expectDidCompleteCheckoutWithData = expectation(description: "checkout completes successfully")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectDidCompleteCheckoutWithData.fulfill()
        }

        sut.start_async()

        wait(for: [
            expectWillCreatePaymentWithData,
            expectDidStartTokenization,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidShowPaymentMethod,
            expectDidResumePayment,
            expectDidCompleteCheckoutWithData
        ], timeout: 15.0, enforceOrder: true)
    }

    // MARK: - Session Info Tests

    func test_adyenVippsSessionInfo_shouldReturnCorrectPlatform() throws {
        sut = WebRedirectPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.adyenVippsPaymentMethod,
                                                            uiManager: uiManager,
                                                            tokenizationService: tokenizationService,
                                                            createResumePaymentService: createResumePaymentService,
                                                            deeplinkAbilityProvider: MockDeeplinkAbilityProvider(isDeeplinkAvailable: true))

        var sessionInfo = sut.sessionInfo()
        XCTAssertEqual(sessionInfo.platform, "IOS")

        sut = WebRedirectPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.adyenVippsPaymentMethod,
                                                            uiManager: uiManager,
                                                            tokenizationService: tokenizationService,
                                                            createResumePaymentService: createResumePaymentService,
                                                            deeplinkAbilityProvider: MockDeeplinkAbilityProvider(isDeeplinkAvailable: false))

        sessionInfo = sut.sessionInfo()
        XCTAssertEqual(sessionInfo.platform, "WEB")
    }
}
