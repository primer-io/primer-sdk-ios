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

    // TODO: Enable Cancellation
//    func test_startFlow_withCancellation_shouldCallOnDidFail() throws {
//        SDKSessionHelper.setUp()
//
//        sut.start_async()
//
//        delegate.onWillCreatePaymentWithData = { data, decision in
//            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
//                decision(.continuePaymentCreation())
//            }
//        }
//
//        let expectDidFail = self.expectation(description: "onDidFail called")
//        delegate.onDidFail = { error in
//            switch error {
//            case PrimerError.cancelled(let paymentMethodType, _, _):
//                XCTAssertEqual(paymentMethodType, Mocks.Static.Strings.webRedirectPaymentMethodType)
//            default:
//                XCTFail()
//            }
//            expectDidFail.fulfill()
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            let cancelNotif = Notification(name: Notification.Name.receivedUrlSchemeCancellation)
//            NotificationCenter.default.post(cancelNotif)
//        }
//
//        waitForExpectations(timeout: 10.0)
//    }

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentWithData = self.expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.abortPaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidFail = self.expectation(description: "flow fails with error")
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

        let expectWillCreatePaymentWithData = self.expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidStartTokenization = self.expectation(description: "tokenization begins")
        delegate.onDidStartTokenization = { type in
            XCTAssertEqual(type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            expectDidStartTokenization.fulfill()
        }

        let expectDidTokenize = self.expectation(description: "payment method tokenized")
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

        let expectDidCreatePayment = self.expectation(description: "payment created")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return .init(id: "id",
                         paymentId: "payment_id",
                         amount: 123,
                         currencyCode: "GBP",
                         customerId: "customer_id",
                         orderId: "order_id",
                         requiredAction: .init(clientToken: MockAppState.mockClientTokenWithRedirect,
                                               name: .checkout,
                                               description: "description"),
                         status: .success)
        }

        let expectDidShowPaymentMethod = self.expectation(description: "payment method UI presented")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            XCTAssertNotNil(self.sut.webViewController?.delegate)
            expectDidShowPaymentMethod.fulfill()
        }

        let expectDidResumePayment = self.expectation(description: "payment resumed")
        createResumePaymentService.onResumePayment = { paymentId, request in
            XCTAssertEqual(paymentId, "id")
            XCTAssertEqual(request.resumeToken, "4321")
            expectDidResumePayment.fulfill()
            return .init(id: "id",
                         paymentId: "payment_id",
                         amount: 1234,
                         currencyCode: "GBP",
                         customerId: "customer_id",
                         orderId: "order_id",
                         status: .success)
        }

        let expectDidCompleteCheckoutWithData = self.expectation(description: "checkout completes successfully")
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
