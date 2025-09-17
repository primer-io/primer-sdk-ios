//
//  PayPalTokenizationViewModelTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PayPalTokenizationViewModelTests: XCTestCase {
    // MARK: - Test Dependencies

    var sut: PayPalTokenizationViewModel!
    var uiManager: MockPrimerUIManager!
    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!

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

    // MARK: - Async Flow Tests

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, PrimerPaymentMethodType.payPal.rawValue)
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

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, PrimerPaymentMethodType.payPal.rawValue)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidShowPaymentMethod = self.expectation(description: "UI shows payment method")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            expectDidShowPaymentMethod.fulfill()
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

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentWithData,
            expectDidShowPaymentMethod,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidCompleteCheckout
        ], timeout: 10.0, enforceOrder: true)
    }
}
