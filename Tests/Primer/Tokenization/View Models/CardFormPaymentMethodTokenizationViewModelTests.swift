//
//  CardFormPaymentMethodTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 23/05/2024.
//

import XCTest
@testable import PrimerSDK

final class CardFormPaymentMethodTokenizationViewModelTests: XCTestCase, TokenizationViewModelTestCase {

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
        sut = CardFormPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.paymentCardPaymentMethod,
                                                         uiManager: uiManager,
                                                         tokenizationService: tokenizationService,
                                                         createResumePaymentService: createResumePaymentService)

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        PrimerInternal.shared.intent = .checkout
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    func testStartWithPreTokenizationAndAbort() throws {
        setupAppState(amount: 1234, currencyCode: "GBP")
        SDKSessionHelper.setUp()

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")
            decision(.abortPaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectWillShowPaymentMethod = self.expectation(description: "Did show payment method")
        uiDelegate.onUIDidShowPaymentMethod = { type in
            self.sut.userInputCompletion?()
            expectWillShowPaymentMethod.fulfill()
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

        waitForExpectations(timeout: 10.0)
    }

    func testStartWithFullCheckoutFlow() throws {
        setupAppState(amount: 1234, currencyCode: "GBP")
        SDKSessionHelper.setUp(checkoutModules: [checkoutModule])

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        _ = PrimerUIManager.prepareRootViewController()

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")

            self.fillFormFields()

            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectCheckoutDidCompletewithData = self.expectation(description: "")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectCheckoutDidCompletewithData.fulfill()
        }

        let expectOnTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { body in
            expectOnTokenize.fulfill()
            return Promise.fulfilled(self.tokenizationResponseBody)
        }

        let expectWillShowPaymentMethod = self.expectation(description: "Did show payment method")
        uiDelegate.onUIDidShowPaymentMethod = { type in
            self.sut.userInputCompletion?()
            expectWillShowPaymentMethod.fulfill()
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { body in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody

        }

        sut.start()

        wait(for: [
            expectWillShowPaymentMethod,
            expectWillCreatePaymentData,
            expectOnTokenize,
            expectDidCreatePayment,
            expectCheckoutDidCompletewithData
        ], timeout: 10.0, enforceOrder: true)
    }

    func testValidate() throws {
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
