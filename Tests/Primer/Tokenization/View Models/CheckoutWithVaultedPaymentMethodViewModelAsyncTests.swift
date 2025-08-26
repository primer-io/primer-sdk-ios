@testable import PrimerSDK
import XCTest

final class CheckoutWithVaultedPaymentMethodViewModelAsyncTests: XCTestCase {
    // MARK: - Test Dependencies

    private var sut: CheckoutWithVaultedPaymentMethodViewModel!
    private var tokenizationService: MockTokenizationService!
    private var createResumePaymentService: MockCreateResumePaymentService!

    // MARK: - Test Helper Data

    private let tokenizationResponseBody = Response.Body.Tokenization(
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

    private let paymentResponseBody = Response.Body.Payment(
        id: "id",
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
        status: .success
    )

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        sut = CheckoutWithVaultedPaymentMethodViewModel(
            configuration: Mocks.PaymentMethods.paymentCardPaymentMethod,
            selectedPaymentMethodTokenData: Mocks.primerPaymentMethodTokenData,
            additionalData: nil,
            tokenizationService: tokenizationService,
            createResumePaymentService: createResumePaymentService
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        createResumePaymentService = nil
        tokenizationService = nil
    }

    // MARK: - Async Flow Tests

    func test_startFlow_whenAborted_shouldCallOnDidFail() async throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentWithData = self.expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")
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

        try await sut.start()

        await fulfillment(of: [
            expectWillCreatePaymentWithData,
            expectDidFail
        ],
        timeout: 5.0)
    }

    func test_startFlow_fullCheckout_shouldCompleteSuccessfully() async throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectWillCreatePaymentWithData = self.expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidExchangeToken = self.expectation(description: "payment method token exchanged")
        tokenizationService.onExchangePaymentMethodToken = { tokenId, _ in
            XCTAssertEqual(tokenId, "mock_payment_method_token_data_id")
            expectDidExchangeToken.fulfill()
            return Result.success(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "payment created")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectDidCompleteCheckoutWithData = self.expectation(description: "checkout completes successfully")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectDidCompleteCheckoutWithData.fulfill()
        }

        delegate.onDidFail = { error in
            print(error)
        }

        let expectPromiseResolved = self.expectation(description: "start promise resolves")
        Task {
            do {
                try await sut.start()
                expectPromiseResolved.fulfill()
            } catch {
                XCTFail()
            }
        }

        await fulfillment(of: [
            expectWillCreatePaymentWithData,
            expectDidExchangeToken,
            expectDidCreatePayment,
            expectDidCompleteCheckoutWithData,
            expectPromiseResolved
        ], timeout: 10.0, enforceOrder: true)
    }
}
