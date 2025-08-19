//
//  WebRedirectPaymentMethodTokenizationViewModelAsyncTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class WebRedirectPaymentMethodTokenizationViewModelAsyncTests: XCTestCase {
    // MARK: - Test Dependencies
    
    private var sut: WebRedirectPaymentMethodTokenizationViewModel!
    private var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    private var uiDelegate: MockPrimerHeadlessUniversalCheckoutUIDelegate!
    private var apiClient: MockPrimerAPIClient!
    private var uiManager: MockPrimerUIManager!
    private var createResumePaymentService: MockCreateResumePaymentService!
    private var tokenizationService: MockTokenizationService!
    private let expectedPaymentMethodType: String = Mocks.PaymentMethods.webRedirectPaymentMethod.type

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        PollingModule.apiClient = apiClient

        uiManager = MockPrimerUIManager()
        uiManager.primerRootViewController = MockPrimerRootViewController()

        createResumePaymentService = MockCreateResumePaymentService()
        tokenizationService = MockTokenizationService()

        sut = WebRedirectPaymentMethodTokenizationViewModel(
            config: Mocks.PaymentMethods.webRedirectPaymentMethod,
            uiManager: uiManager,
            tokenizationService: tokenizationService,
            createResumePaymentService: createResumePaymentService
        )
    }

    override func tearDownWithError() throws {
        delegate = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil

        uiDelegate = nil
        PrimerHeadlessUniversalCheckout.current.uiDelegate = nil

        apiClient = nil
        PrimerAPIConfigurationModule.apiClient = nil
        PollingModule.apiClient = nil

        uiManager.primerRootViewController = nil
        uiManager = nil

        createResumePaymentService = nil
        tokenizationService = nil
        sut = nil

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

    func test_startFlow_withImmediateCancellation_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.webRedirectPaymentMethod])
     
        let expectDidFail = expectation(description: "onDidFail called with cancellation error")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.cancelled(let paymentMethodType, _):
                XCTAssertEqual(paymentMethodType, self.expectedPaymentMethodType)
            default:
                XCTFail("Expected cancellation error, got \(error)")
            }
            expectDidFail.fulfill()
        }

        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, self.expectedPaymentMethodType)
            decision(.continuePaymentCreation())
        }

        sut.start_async()

        let cancelNotification = Notification(name: Notification.Name.receivedUrlSchemeCancellation)
        NotificationCenter.default.post(cancelNotification)

        wait(for: [expectDidFail], timeout: 2.0)
    }

    func test_startFlow_withDelayedCancellation_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp()

        let expectDidFail = expectation(description: "onDidFail called with cancellation error")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.cancelled(let paymentMethodType, _):
                XCTAssertEqual(paymentMethodType, Mocks.Static.Strings.webRedirectPaymentMethodType)
            default:
                XCTFail("Expected cancellation error, got \(error)")
            }
            expectDidFail.fulfill()
        }

        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.continuePaymentCreation())
        }

        tokenizationService.onTokenize = { _ in
            sleep(1)
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
        sut.start_async()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let cancelNotification = Notification(name: Notification.Name.receivedUrlSchemeCancellation)
            NotificationCenter.default.post(cancelNotification)
        }

        wait(for: [expectDidFail], timeout: 2.0)
    }

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.webRedirectPaymentMethod])

        let expectWillCreatePaymentWithData = expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, self.expectedPaymentMethodType)
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
//        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.webRedirectPaymentMethod])
        SDKSessionHelper.setUp()
        
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "4321", source: "src"), nil)
        ]

        let expectWillCreatePaymentWithData = expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, self.expectedPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidStartTokenization = expectation(description: "tokenization begins")
        delegate.onDidStartTokenization = { type in
            XCTAssertEqual(type, self.expectedPaymentMethodType)
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
                    paymentMethodType: self.expectedPaymentMethodType,
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
