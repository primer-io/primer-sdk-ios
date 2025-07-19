@testable import PrimerSDK
import XCTest

final class CardFormPaymentMethodTokenizationViewModelAsyncTests: XCTestCase, TokenizationViewModelTestCase {
    var apiClient: MockPrimerAPIClient!
    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!
    var uiManager: MockPrimerUIManager!
    var sut: CardFormPaymentMethodTokenizationViewModel!
    var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    var uiDelegate: MockPrimerHeadlessUniversalCheckoutUIDelegate!

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        uiManager.primerRootViewController = MockPrimerRootViewController()
        sut = CardFormPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.paymentCardPaymentMethod,
                                                         uiManager: uiManager,
                                                         tokenizationService: tokenizationService,
                                                         createResumePaymentService: createResumePaymentService)

        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate
        apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient

        PrimerInternal.shared.intent = .checkout
    }

    override func tearDownWithError() throws {
        apiClient = nil
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    func test_validate() throws {
        SDKSessionHelper.tearDown()
        XCTAssertThrowsError(try sut.validate())

        try SDKSessionHelper.test {
            PrimerInternal.shared.intent = .none
            setupAppState()
            XCTAssertNoThrow(try sut.validate())

            PrimerInternal.shared.intent = .checkout
            XCTAssertThrowsError(try sut.validate())

            setupAppState(amount: 1234)
            XCTAssertThrowsError(try sut.validate())

            setupAppState(currencyCode: "GBP")
            XCTAssertThrowsError(try sut.validate())

            setupAppState(amount: 1234, currencyCode: "GBP")
            XCTAssertNoThrow(try sut.validate())
        }
    }

    func test_start_with_pre_tokenization_and_abort_async() throws {
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }

        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectOnDidShowPaymentMethod = self.expectation(description: "onUIDidShowPaymentMethod is called")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectOnDidShowPaymentMethod.fulfill()
        }

        let expectOnWillCreatePaymentWithData = self.expectation(description: "onWillCreatePaymentWithData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")
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
            expectOnDidShowPaymentMethod,
            expectOnWillCreatePaymentWithData,
            expectOnDidFail
        ], timeout: 10, enforceOrder: true)
    }

    func test_start_with_full_checkout_flow_async() throws {
        SDKSessionHelper.setUp(checkoutModules: [checkoutModule]) { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }

        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectOnDidShowPaymentMethod = self.expectation(description: "onUIDidShowPaymentMethod is called")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectOnDidShowPaymentMethod.fulfill()
        }

        let expectOnWillCreatePaymentWithData = self.expectation(description: "onWillCreatePaymentWithData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")

            self.fillFormFields()

            decision(.continuePaymentCreation())
            expectOnWillCreatePaymentWithData.fulfill()
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

        sut.start_async()

        wait(for: [
            expectOnDidShowPaymentMethod,
            expectOnWillCreatePaymentWithData,
            expectOnTokenize,
            expectOnCreatePayment,
            expectOnDidCompleteCheckoutWithData
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_setCheckoutDataFromError() throws {
        let sut = PaymentMethodTokenizationViewModel(config: PrimerPaymentMethod(id: "id",
                                                                                 implementationType: .nativeSdk,
                                                                                 type: "PMT",
                                                                                 name: "",
                                                                                 processorConfigId: nil,
                                                                                 surcharge: nil,
                                                                                 options: nil,
                                                                                 displayMetadata: nil))

        let error = PrimerError.paymentFailed(paymentMethodType: "PMT",
                                              paymentId: "123",
                                              orderId: "OrderId",
                                              status: "FAILED",
                                              userInfo: nil,
                                              diagnosticsId: "id")
        sut.setCheckoutDataFromError(error)

        XCTAssertEqual(sut.paymentCheckoutData?.payment?.id, "123")
        XCTAssertEqual(sut.paymentCheckoutData?.payment?.orderId, "OrderId")
        XCTAssertEqual(sut.paymentCheckoutData?.payment?.paymentFailureReason, PrimerPaymentErrorCode.failed)

        let error2 = PrimerError.cancelled(paymentMethodType: "PMT", userInfo: nil, diagnosticsId: "id")
        XCTAssertNil(error2.checkoutData)
    }

    func test_start_with_submit_button_disabled() throws {
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }

        let expectWillShowPaymentMethod = self.expectation(description: "Did show payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            // Fill in fields with invalid data
            self.sut.cardNumberField.textField.internalText = "4111" // Incomplete number
            self.sut.expiryDateField.expiryYear = "30"
            self.sut.expiryDateField.expiryMonth = "03"
            self.sut.cvvField.textField.internalText = "12" // Invalid CVV

            // Simulate validation of each field
            self.sut.primerTextFieldView(self.sut.cardNumberField, isValid: false)
            self.sut.primerTextFieldView(self.sut.expiryDateField, isValid: true)
            self.sut.primerTextFieldView(self.sut.cvvField, isValid: false)

            expectWillShowPaymentMethod.fulfill()
        }

        sut.start_async()

        waitForExpectations(timeout: 10.0)

        XCTAssertFalse(self.sut.uiModule.submitButton?.isEnabled == true)
    }

    func testConfigurePayButton_defaultShowsPayAmount() throws {
        // Arrange: set up AppState with amount & currency
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 2500 // $25.00
            mockAppState.currency = Currency(code: "USD", decimalDigits: 2)
        }
        PrimerInternal.shared.intent = .checkout

        // Register default settings (no cardFormUIOptions)
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)

        // Act: call configurePayButton
        sut.configurePayButton(amount: 2500)

        // Assert: should use "Pay $25.00"
        let expectedCurrency = Currency(code: "USD", decimalDigits: 2)
        let expectedTitle = "\(Strings.PaymentButton.pay) \(2500.toCurrencyString(currency: expectedCurrency))"
        XCTAssertEqual(
            sut.uiModule.submitButton?.title(for: .normal),
            expectedTitle,
            "Default behavior should show formatted pay amount"
        )
    }

    func testConfigurePayButton_showsAddNewCard_whenFlagTrue() throws {
        // Arrange: set up AppState
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 500 // €5.00
            mockAppState.currency = Currency(code: "EUR", decimalDigits: 2)
        }
        PrimerInternal.shared.intent = .checkout

        // Register settings with payButtonAddNewCard = true
        let uiOptions = PrimerUIOptions(
            cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: true)
        )
        DependencyContainer.register(PrimerSettings(uiOptions: uiOptions) as PrimerSettingsProtocol)

        // Act
        sut.configurePayButton(amount: 500)

        // Assert: should use the localized "Add new card" text
        XCTAssertEqual(
            sut.uiModule.submitButton?.title(for: .normal),
            Strings.VaultPaymentMethodViewContent.addCard,
            "When payButtonAddNewCard=true, the button should read 'Add new card'"
        )
    }

    // MARK: Helpers

    private var checkoutModule: PrimerAPIConfiguration.CheckoutModule {
        let options = PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions(
            firstName: true,
            lastName: true,
            city: true,
            postalCode: true,
            addressLine1: true,
            addressLine2: true,
            countryCode: true,
            phoneNumber: true,
            state: true
        )
        return PrimerAPIConfiguration.CheckoutModule(type: "BILLING_ADDRESS",
                                                     requestUrlStr: "request_url_str",
                                                     options: options)
    }

    private func fillFormFields() {
        self.sut.cardNumberField.textField.internalText = "4111 1111 1111 1111"
        self.sut.expiryDateField.expiryYear = "30"
        self.sut.expiryDateField.expiryMonth = "03"
        self.sut.cvvField.textField.internalText = "123"
        self.sut.cvvField.cardNetwork = .visa

        self.sut.firstNameFieldView.textField.internalText = "John"

        self.sut.lastNameFieldView.textField.internalText = "Appleseed"

        self.sut.addressLine1FieldView.textField.internalText = "123 King Street"
        self.sut.addressLine2FieldView.textField.internalText = "St Pauls"
        self.sut.cityFieldView.textField.internalText = "London"
        self.sut.postalCodeFieldView.textField.internalText = "EC4M 1AB"
        self.sut.countryFieldView.textField.internalText = "GB"
    }
}
