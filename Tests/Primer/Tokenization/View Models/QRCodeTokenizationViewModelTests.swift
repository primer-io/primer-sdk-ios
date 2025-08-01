//
//  QRCodeTokenizationViewModelTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class QRCodeTokenizationViewModelTests: XCTestCase {

    var uiManager: MockPrimerUIManager!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var sut: QRCodeTokenizationViewModel!

    override func setUpWithError() throws {

        uiManager = MockPrimerUIManager()
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
    }

    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let mockViewController = MockPrimerRootViewController()
        uiManager.onPrepareViewController = {
            self.uiManager.primerRootViewController = mockViewController
        }

        _ = uiManager.prepareRootViewController()

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
            decision(.abortPaymentCreation())
            expectWillCreatePaymentData.fulfill()
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

        wait(for: [
            expectWillCreatePaymentData,
            expectWillAbort
        ], timeout: 10.0, enforceOrder: true)
    }

    func testStartWithFullCheckoutFlow() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let mockViewController = MockPrimerRootViewController()
        uiManager.onPrepareViewController = {
            self.uiManager.primerRootViewController = mockViewController
        }

        _ = uiManager.prepareRootViewController()

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
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
        tokenizationService.onTokenize = { _ in
            expectOnTokenize.fulfill()
            return .success(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectOnTokenize,
            expectDidCreatePayment,
            expectCheckoutDidCompletewithData
        ], timeout: 10.0, enforceOrder: true)
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
