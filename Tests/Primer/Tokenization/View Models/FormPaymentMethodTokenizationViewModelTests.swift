//
//  FormPaymentMethodTokenizationViewModelTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class FormPaymentMethodTokenizationViewModelTests: XCTestCase {
    
    // MARK: - Test Dependencies
    
    var sut: FormPaymentMethodTokenizationViewModel!
    var uiManager: MockPrimerUIManager!
    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!
    var uiDelegate: MockPrimerHeadlessUniversalCheckoutUIDelegate!

    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        uiManager.primerRootViewController = MockPrimerRootViewController()
        
        sut = FormPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.adyenBlikPaymentMethod,
                                                     uiManager: uiManager,
                                                     tokenizationService: tokenizationService,
                                                     createResumePaymentService: createResumePaymentService)
        
        uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate
        
        PrimerInternal.shared.intent = .checkout
    }

    override func tearDownWithError() throws {
        uiDelegate = nil
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    // MARK: - Async Flow Tests
    
    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectDidShowPaymentMethod = self.expectation(description: "UI shows payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectDidShowPaymentMethod.fulfill()
        }

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_BLIK")
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
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_startFlow_fullCheckout_shouldCompleteSuccessfully() throws {
        SDKSessionHelper.setUp { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectDidShowPaymentMethod = self.expectation(description: "UI shows payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectDidShowPaymentMethod.fulfill()
        }

        sut.inputs.append(MockInput(name: "blikCode", text: "123456"))

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_BLIK")
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidCompleteCheckout = self.expectation(description: "Checkout completes successfully")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectDidCompleteCheckout.fulfill()
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

        delegate.onDidFail = { error in
            print(error)
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

    // MARK: - Test Helper Data

    private var tokenizationResponseBody: Response.Body.Tokenization {
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

    private var paymentResponseBody: Response.Body.Payment {
        .init(id: "id",
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
              status: .success)
    }
}

private final class MockInput: Input {
    override var text: String? { mockText }
    private var mockText: String?

    init(name: String, text: String) {
        super.init()
        self.name = name
        self.mockText = text
    }
}
