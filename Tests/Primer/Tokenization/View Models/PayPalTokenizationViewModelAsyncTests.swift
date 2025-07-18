@testable import PrimerSDK
import XCTest

final class PayPalTokenizationViewModelAsyncTests: XCTestCase {
    var uiManager: MockPrimerUIManager!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var sut: PayPalTokenizationViewModel!

    override func setUpWithError() throws {
        uiManager = MockPrimerUIManager()
        uiManager.primerRootViewController = MockPrimerRootViewController()
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()

        sut = PayPalTokenizationViewModel(config: Mocks.PaymentMethods.paypalPaymentMethod,
                                          uiManager: uiManager,
                                          tokenizationService: tokenizationService,
                                          createResumePaymentService: createResumePaymentService)
    }

    override func tearDownWithError() throws {
        sut = nil
        createResumePaymentService = nil
        tokenizationService = nil
        uiManager = nil
    }

    func test_start_with_pre_tokenization_and_abort_async() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let expectOnWillCreatePaymentWithData = self.expectation(description: "onWillCreatePaymentWithData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, PrimerPaymentMethodType.payPal.rawValue)
            decision(.abortPaymentCreation())
            expectOnWillCreatePaymentWithData.fulfill()
        }

        let expectOnDidFail = self.expectation(description: "onDidFail is called")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError:
                break
            default:
                XCTFail()
            }
            expectOnDidFail.fulfill()
        }

        sut.start_async()

        wait(for: [
            expectOnWillCreatePaymentWithData,
            expectOnDidFail
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_start_with_full_checkout_flow_async() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        PrimerInternal.shared.intent = .checkout

        let settings = PrimerSettings(paymentMethodOptions: .init(urlScheme: "urlscheme://app"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let payPalService = MockPayPalService()
        sut.payPalService = payPalService
        payPalService.onStartOrderSession = {
            .init(orderId: "order_id", approvalUrl: "https://approval.url/")
        }
        payPalService.onFetchPayPalExternalPayerInfo = { _ in
            .init(orderId: "order_id", externalPayerInfo: .init(externalPayerId: "external_payer_id",
                                                                email: "john@appleseed.com",
                                                                firstName: "John",
                                                                lastName: "Appleseed"))
        }

        let webAuthenticationService = MockWebAuthenticationService()
        sut.webAuthenticationService = webAuthenticationService
        webAuthenticationService.onConnect = { _, _ in
            URL(string: "https://webauthsvc.app/")!
        }

        let expectOnWillCreatePaymentWithData = self.expectation(description: "onWillCreatePaymentWithData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, PrimerPaymentMethodType.payPal.rawValue)
            decision(.continuePaymentCreation())
            expectOnWillCreatePaymentWithData.fulfill()
        }

        let expectOnDidShowPaymentMethod = self.expectation(description: "onUIDidShowPaymentMethod is called")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            expectOnDidShowPaymentMethod.fulfill()
        }

        let expectOnTokenize = self.expectation(description: "onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectOnTokenize.fulfill()
            return .success(self.tokenizationResponseBody)
        }

        let expectOnCreatePayment = self.expectation(description: "onCreatePayment is called")
        createResumePaymentService.onCreatePayment = { _ in
            expectOnCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectOnDidCompleteCheckoutWithData = self.expectation(description: "onDidCompleteCheckoutWithData is called")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectOnDidCompleteCheckoutWithData.fulfill()
        }

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start_async()

        wait(for: [
            expectOnWillCreatePaymentWithData,
            expectOnDidShowPaymentMethod,
            expectOnTokenize,
            expectOnCreatePayment,
            expectOnDidCompleteCheckoutWithData
        ], timeout: 20.0, enforceOrder: true)
    }

    // MARK: Helpers

    var tokenizationResponseBody: Response.Body.Tokenization {
        .init(analyticsId: "analytics_id",
              id: "id",
              isVaulted: false,
              isAlreadyVaulted: false,
              paymentInstrumentType: .offSession,
              paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
              paymentInstrumentData: nil,
              threeDSecureAuthentication: nil,
              token: "token",
              tokenType: .singleUse,
              vaultData: nil)
    }

    var paymentResponseBody: Response.Body.Payment {
        return .init(id: "id",
                     paymentId: "payment_id",
                     amount: 123,
                     currencyCode: "GBP",
                     customer: .init(firstName: "first_name",
                                     lastName: "last_name",
                                     emailAddress: "email_address",
                                     mobileNumber: "+44(0)7891234567",
                                     billingAddress: .init(firstName: "billing_first_name",
                                                           lastName: "billing_last_name",
                                                           addressLine1: "billing_line_1",
                                                           addressLine2: "billing_line_2",
                                                           city: "billing_city",
                                                           state: "billing_state",
                                                           countryCode: "billing_country_code",
                                                           postalCode: "billing_postal_code"),
                                     shippingAddress: .init(firstName: "shipping_first_name",
                                                            lastName: "shipping_last_name",
                                                            addressLine1: "shipping_line_1",
                                                            addressLine2: "shipping_line_2",
                                                            city: "shipping_city",
                                                            state: "shipping_state",
                                                            countryCode: "shipping_country_code",
                                                            postalCode: "shipping_postal_code")),
                     customerId: "customer_id",
                     orderId: "order_id",
                     status: .success)
    }
}
