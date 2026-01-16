//
//  QRCodeTokenizationViewModelTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class QRCodeTokenizationViewModelTests: XCTestCase {
    // MARK: - Test Dependencies

    var sut: QRCodeTokenizationViewModel!
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

    // TODO: Extract to helper
    private let paymentResponseBody = Response.Body.Payment(
        id: "id",
        paymentId: "payment_id",
        amount: 123,
        currencyCode: "GBP",
        customer: Request.Body.ClientSession.Customer(
            firstName: "first_name",
            lastName: "last_name",
            emailAddress: "email_address",
            mobileNumber: "+44(0)7891234567",
            billingAddress: PaymentAPIModelAddress(
                firstName: "billing_first_name",
                lastName: "billing_last_name",
                addressLine1: "billing_line_1",
                addressLine2: "billing_line_2",
                city: "billing_city",
                state: "billing_state",
                countryCode: "billing_country_code",
                postalCode: "billing_postal_code"
            ),
            shippingAddress: PaymentAPIModelAddress(
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

        sut = QRCodeTokenizationViewModel(config: Mocks.PaymentMethods.adyenIDealPaymentMethod,
                                          uiManager: uiManager,
                                          tokenizationService: tokenizationService,
                                          createResumePaymentService: createResumePaymentService)
    }

    override func tearDownWithError() throws {
        sut = nil
        createResumePaymentService = nil
        tokenizationService = nil
        uiManager = nil
        SDKSessionHelper.tearDown()
    }

    // MARK: - Flow Tests

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let expectWillCreatePaymentWithData = expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
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

        sut.start()

        wait(for: [expectWillCreatePaymentWithData, expectDidFail], timeout: 10.0, enforceOrder: true)
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

        let expectWillCreatePaymentWithData = expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidCompleteCheckoutWithData = expectation(description: "checkout completes successfully")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectDidCompleteCheckoutWithData.fulfill()
        }

        let expectDidTokenize = expectation(description: "payment method tokenized")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return .success(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = expectation(description: "payment created")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentWithData,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidCompleteCheckoutWithData
        ], timeout: 10.0, enforceOrder: true)
    }
}
