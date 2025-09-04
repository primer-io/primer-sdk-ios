//
//  CardFormPaymentMethodTokenizationViewModelTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class CardFormPaymentMethodTokenizationViewModelTests: XCTestCase, TokenizationViewModelTestCase {
    
    // MARK: - Test Dependencies
    
    var sut: CardFormPaymentMethodTokenizationViewModel!
    var apiClient: MockPrimerAPIClient!
    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!
    var uiManager: MockPrimerUIManager!
    var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    var uiDelegate: MockPrimerHeadlessUniversalCheckoutUIDelegate!

    // MARK: - Setup & Teardown
    
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

    // MARK: - Validation Tests

    func test_validation_requiresValidConfiguration() throws {
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

    // MARK: - Async Flow Tests

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }

        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectDidShowPaymentMethod = self.expectation(description: "UI shows payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectDidShowPaymentMethod.fulfill()
        }

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")
            decision(.abortPaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidFail = self.expectation(description: "Payment flow fails")
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
        ], timeout: 10, enforceOrder: true)
    }

    func test_startFlow_fullCheckout_shouldCompleteSuccessfully() throws {
        SDKSessionHelper.setUp(checkoutModules: [checkoutModule]) { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }

        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectDidShowPaymentMethod = self.expectation(description: "UI shows payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectDidShowPaymentMethod.fulfill()
        }

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")

            self.fillFormFields()

            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidTokenize = self.expectation(description: "Payment method tokenizes")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return .success(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "Payment gets created")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectDidCompleteCheckout = self.expectation(description: "Checkout completes successfully")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectDidCompleteCheckout.fulfill()
        }

        sut.start()

        wait(for: [
            expectDidShowPaymentMethod,
            expectWillCreatePaymentWithData,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidCompleteCheckout
        ], timeout: 10.0, enforceOrder: true)
    }

    // MARK: - Error Handling Tests

    func test_setCheckoutDataFromError_shouldSetCorrectPaymentData() throws {
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
                                              diagnosticsId: "id")
        sut.setCheckoutDataFromError(error)

        XCTAssertEqual(sut.paymentCheckoutData?.payment?.id, "123")
        XCTAssertEqual(sut.paymentCheckoutData?.payment?.orderId, "OrderId")
        XCTAssertEqual(sut.paymentCheckoutData?.payment?.paymentFailureReason, PrimerPaymentErrorCode.failed)

        let error2 = PrimerError.cancelled(paymentMethodType: "PMT", diagnosticsId: "id")
        XCTAssertNil(error2.checkoutData)
    }

    // MARK: - UI Interaction Tests

    func test_startFlow_withInvalidFields_shouldDisableSubmitButton() throws {
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }

        let expectDidShowPaymentMethod = self.expectation(description: "UI shows payment method")
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

            expectDidShowPaymentMethod.fulfill()
        }

        sut.start()

        waitForExpectations(timeout: 10.0)

        XCTAssertFalse(self.sut.uiModule.submitButton?.isEnabled == true)
    }

    func test_configurePayButton_defaultBehavior_shouldShowPayAmount() throws {
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

    func test_configurePayButton_withAddNewCardFlag_shouldShowAddCardText() throws {
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

    // MARK: - Test Helper Data

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
