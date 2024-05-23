//
//  CheckoutWithVaultedPaymentMethodViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 07/05/2024.
//

import XCTest
@testable import PrimerSDK

final class CheckoutWithVaultedPaymentMethodViewModelTests: XCTestCase {
    
    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var sut: CheckoutWithVaultedPaymentMethodViewModel!

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        sut = CheckoutWithVaultedPaymentMethodViewModel(configuration: Mocks.PaymentMethods.paymentCardPaymentMethod,
                                                        selectedPaymentMethodTokenData: Mocks.primerPaymentMethodTokenData,
                                                        additionalData: nil,
                                                        tokenizationService: tokenizationService,
                                                        createResumePaymentService: createResumePaymentService)
    }

    override func tearDownWithError() throws {
        sut = nil
    }


    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")
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

        _ = sut.start()

        waitForExpectations(timeout: 2.0)
    }

    func testStartWithFullCheckoutFlow() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "PAYMENT_CARD")
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectCheckoutDidCompletewithData = self.expectation(description: "")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectCheckoutDidCompletewithData.fulfill()
        }

//        let expectOnTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
//        tokenizationService.onTokenize = { body in
//            expectOnTokenize.fulfill()
//            return Promise.fulfilled(self.tokenizationResponseBody)
//        }

        let expectDidExchangeToken = self.expectation(description: "didExchangeToken called")
        tokenizationService.onExchangePaymentMethodToken = { tokenId, data in
            XCTAssertEqual(tokenId, "mock_payment_method_token_data_id")
            expectDidExchangeToken.fulfill()
            return Promise.fulfilled(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { body in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody

        }

        delegate.onDidFail = { error in
            print(error)
        }

        let expectPromiseResolved = self.expectation(description: "Expect start promise to resolve")
        _ = sut.start().done {
            expectPromiseResolved.fulfill()
        }

        wait(for: [
            expectWillCreatePaymentData,
            expectDidExchangeToken,
            expectDidCreatePayment,
            expectCheckoutDidCompletewithData,
            expectPromiseResolved
        ], timeout: 10.0, enforceOrder: true)
    }

    func testHandleSuccessFlow() throws {
        let expectation = self.expectation(description: "Results controller is displayed")

        _ = PrimerUIManager.prepareRootViewController().done { _ in
            PrimerUIManager.primerRootViewController?.navController.setViewControllers([], animated: false)
            self.sut.handleSuccessfulFlow()

            let viewControllers = PrimerUIManager.primerRootViewController!.navController.viewControllers
            XCTAssertEqual(viewControllers.count, 1)
            XCTAssertTrue(viewControllers.first! is PrimerContainerViewController)
            let childViewController = (viewControllers.first as! PrimerContainerViewController).childViewController
            XCTAssertTrue(childViewController is PrimerResultViewController)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testHandleFailureFlow() throws {
        let expectation = self.expectation(description: "Results controller is displayed")

        _ = PrimerUIManager.prepareRootViewController().done { _ in
            PrimerUIManager.primerRootViewController?.navController.setViewControllers([], animated: false)
            self.sut.handleFailureFlow(errorMessage: "Message")

            let viewControllers = PrimerUIManager.primerRootViewController!.navController.viewControllers
            XCTAssertEqual(viewControllers.count, 1)
            XCTAssertTrue(viewControllers.first! is PrimerContainerViewController)
            let childViewController = (viewControllers.first as! PrimerContainerViewController).childViewController
            XCTAssertTrue(childViewController is PrimerResultViewController)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
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
                     dateStr: nil,
                     order: nil,
                     orderId: "order_id",
                     requiredAction: nil,
                     status: .success,
                     paymentFailureReason: nil)
    }
}
