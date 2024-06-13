//
//  FormPaymentMethodTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 24/05/2024.
//

import XCTest
@testable import PrimerSDK

final class FormPaymentMethodTokenizationViewModelTests: XCTestCase {

    var uiManager: MockPrimerUIManager!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var sut: FormPaymentMethodTokenizationViewModel!

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        sut = FormPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.adyenBlikPaymentMethod,
                                                     uiManager: uiManager,
                                                     tokenizationService: tokenizationService,
                                                     createResumePaymentService: createResumePaymentService)
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
    }

    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp() { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let mockViewController = MockPrimerRootViewController()
        uiManager.onPrepareViewController = {
            self.uiManager.primerRootViewController = mockViewController
            return Promise.fulfilled(())
        }

        let expectShowPaymentMethod = self.expectation(description: "Showed view controller")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectShowPaymentMethod.fulfill()
        }

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_BLIK")
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

        wait(for: [
            expectShowPaymentMethod,
            expectWillCreatePaymentData,
            expectWillAbort
        ], timeout: 10.0, enforceOrder: true)
    }

    func testStartWithFullCheckoutFlow() throws {
        SDKSessionHelper.setUp() { mockAppState in
            mockAppState.amount = 1234
            mockAppState.currency = Currency(code: "GBP", decimalDigits: 2)
        }
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
            return Promise.fulfilled(())
        }
        let expectShowPaymentMethod = self.expectation(description: "Showed view controller")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            self.sut.userInputCompletion?()
            expectShowPaymentMethod.fulfill()
        }

        uiManager.prepareRootViewController()

        sut.inputs.append(MockInput(name: "blikCode", text: "123456"))

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_BLIK")
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

//        let expectDidExchangeToken = self.expectation(description: "didExchangeToken called")
//        tokenizationService.onExchangePaymentMethodToken = { tokenId, data in
//            XCTAssertEqual(tokenId, "mock_payment_method_token_data_id")
//            expectDidExchangeToken.fulfill()
//            return Promise.fulfilled(self.tokenizationResponseBody)
//        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { body in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start()
        
        wait(for: [
            expectShowPaymentMethod,
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
                     dateStr: nil,
                     order: nil,
                     orderId: "order_id",
                     requiredAction: nil,
                     status: .success,
                     paymentFailureReason: nil)
    }

}

fileprivate class MockInput: Input {

    var mockText: String?

    override var text: String? { mockText }

    init(name: String, text: String) {
        super.init()
        self.name = name
        self.mockText = text
    }
}
