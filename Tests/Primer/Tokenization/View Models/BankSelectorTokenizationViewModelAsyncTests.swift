@testable import PrimerSDK
import XCTest

final class BankSelectorTokenizationViewModelAsyncTests: XCTestCase {
    // MARK: - Test Dependencies

    private var uiManager: MockPrimerUIManager!
    private var tokenizationService: MockTokenizationService!
    private var createResumePaymentService: MockCreateResumePaymentService!
    private var banksApiClient: MockBanksAPIClient!
    private var sut: BankSelectorTokenizationViewModel!

    // MARK: - Helper Data

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
        customer: .init(
            firstName: "first_name",
            lastName: "last_name",
            emailAddress: "email_address",
            mobileNumber: "+44(0)7891234567",
            billingAddress: .init(
                firstName: "billing_first_name",
                lastName: "billing_last_name",
                addressLine1: "billing_line_1",
                addressLine2: "billing_line_2",
                city: "billing_city",
                state: "billing_state",
                countryCode: "billing_country_code",
                postalCode: "billing_postal_code"
            ),
            shippingAddress: .init(
                firstName: "shipping_first_name",
                lastName: "shipping_last_name",
                addressLine1: "shipping_line_1",
                addressLine2: "shipping_line_2",
                city: "shipping_city",
                state: "shipping_state",
                countryCode: "shipping_country_code",
                postalCode: "shipping_postal_code"
            )
        ),
        customerId: "customer_id",
        orderId: "order_id",
        status: .success
    )

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        uiManager = MockPrimerUIManager()
        uiManager.primerRootViewController = MockPrimerRootViewController()
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        banksApiClient = MockBanksAPIClient()

        sut = BankSelectorTokenizationViewModel(
            config: Mocks.PaymentMethods.adyenIDealPaymentMethod,
            uiManager: uiManager,
            tokenizationService: tokenizationService,
            createResumePaymentService: createResumePaymentService,
            apiClient: banksApiClient
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        createResumePaymentService = nil
        tokenizationService = nil
        uiManager = nil
    }

    // MARK: - Async Flow Tests

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let banks = setupBanksAPIClient()

        let expectDidShowPaymentMethod = expectation(description: "UI shows payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.bankSelectionCompletion?(banks.result.first!)
            expectDidShowPaymentMethod.fulfill()
        }

        let expectWillCreatePaymentWithData = expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
            decision(.abortPaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidFail = expectation(description: "Payment flow fails")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError:
                break
            default:
                XCTFail()
            }
            expectDidFail.fulfill()
        }

        sut.start()

        wait(for: [
            expectDidShowPaymentMethod,
            expectWillCreatePaymentWithData,
            expectDidFail
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_startFlow_fullCheckout_shouldCompleteSuccessfully() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let banks = setupBanksAPIClient()

        let expectDidShowPaymentMethod = expectation(description: "UI shows payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.bankSelectionCompletion?(banks.result.first!)
            expectDidShowPaymentMethod.fulfill()
        }

        let expectWillCreatePaymentWithData = expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidCompleteCheckoutWithData = expectation(description: "Checkout completes successfully")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectDidCompleteCheckoutWithData.fulfill()
        }

        let expectDidTokenize = expectation(description: "Payment method tokenizes")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.success(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = expectation(description: "Payment gets created")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start()

        wait(for: [
            expectDidShowPaymentMethod,
            expectWillCreatePaymentWithData,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidCompleteCheckoutWithData
        ], timeout: 10.0, enforceOrder: true)
    }

    // MARK: - Helpers

    func setupBanksAPIClient() -> BanksListSessionResponse {
        let banks: BanksListSessionResponse = .init(
            result: [.init(id: "id", name: "name", iconUrlStr: "icon", disabled: false)]
        )
        banksApiClient.result = banks

        return banks
    }
}
