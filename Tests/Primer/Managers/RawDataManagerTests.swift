//
//  RawDataManagerTests.swift
//  
//
//  Created by Jack Newcombe on 06/06/2024.
//

import XCTest
@testable import PrimerSDK

final class RawDataManagerTests: XCTestCase {

    var headlessCheckoutDelegate: MockPrimerHeadlessUniversalCheckoutDelegate!

    var rawDataManagerDelegate: MockRawDataManagerDelegate!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var sut: RawDataManager!

    override func setUpWithError() throws {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod])
        headlessCheckoutDelegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        rawDataManagerDelegate = MockRawDataManagerDelegate()
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()

        sut = try RawDataManager(paymentMethodType: "PAYMENT_CARD", delegate: rawDataManagerDelegate)
        sut.tokenizationService = tokenizationService
        sut.createResumePaymentService = createResumePaymentService

        PrimerHeadlessUniversalCheckout.current.delegate = headlessCheckoutDelegate
    }

    override func tearDownWithError() throws {
        sut = nil
        rawDataManagerDelegate = nil

        SDKSessionHelper.tearDown()
    }

    func testFullPaymentFlow() throws {
        let expectDidCompleteCheckout = self.expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { data, decisionHandler in
            expectWillCreatePaymentWithData.fulfill()
            decisionHandler(.continuePaymentCreation())
        }

        let expectOnTokenize = self.expectation(description: "On tokenization complete")
        tokenizationService.onTokenize = { body in
            expectOnTokenize.fulfill()
            return Promise.fulfilled(self.tokenizationResponseBody)
        }

        let expectCreatePayment = self.expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.rawData = PrimerCardData(cardNumber: "4111 1111 1111 1111",
                                     expiryDate: "03/2030",
                                     cvv: "123",
                                     cardholderName: "John Appleseed")

        sut.submit()

        waitForExpectations(timeout: 5.0)
    }

    func testFullPaymentFlowWithRequiredActionResume() throws {
        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        PollingModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "4321", source: "src"), nil)
        ]

        let expectDidCompleteCheckout = self.expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { data, decisionHandler in
            expectWillCreatePaymentWithData.fulfill()
            decisionHandler(.continuePaymentCreation())
        }

        let expectOnTokenize = self.expectation(description: "On tokenization complete")
        tokenizationService.onTokenize = { body in
            expectOnTokenize.fulfill()
            return Promise.fulfilled(self.tokenizationResponseBody)
        }

        let expectCreatePayment = self.expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBodyWithRedirectAction
        }

        let expectResumePayment = self.expectation(description: "On resume payment")
        createResumePaymentService.onResumePayment = { paymentId, request in
            XCTAssertEqual(paymentId, "id")
            XCTAssertEqual(request.resumeToken, "4321")
            expectResumePayment.fulfill()
            return self.paymentResponseAfterResume
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.rawData = PrimerCardData(cardNumber: "4111 1111 1111 1111",
                                     expiryDate: "03/2030",
                                     cvv: "123",
                                     cardholderName: "John Appleseed")

        sut.submit()

        waitForExpectations(timeout: 45.0)
    }

    func testAbortPaymentFlow() throws {
        let expectWillCreatePaymentWithData = self.expectation(description: "Will create payment with data")
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { data, decisionHandler in
            expectWillCreatePaymentWithData.fulfill()
            decisionHandler(.abortPaymentCreation())
        }

        let expectDidFail = self.expectation(description: "Did fail with merchant error")
        headlessCheckoutDelegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError:
                break
            default:
                XCTFail("Expected merchant error")
            }
            expectDidFail.fulfill()
        }

        sut.rawData = PrimerCardData(cardNumber: "4111 1111 1111 1111",
                                     expiryDate: "03/2030",
                                     cvv: "123",
                                     cardholderName: "John Appleseed")

        sut.submit()

        waitForExpectations(timeout: 5.0)
    }

    func testNoRawDataSubmit() {

        let expectDidFail = self.expectation(description: "Did fail")
        headlessCheckoutDelegate.onDidFail = { error in
            switch error {
            case PrimerError.invalidValue(let key, let value, _, _):
                XCTAssertEqual(key, "rawData")
                XCTAssertNil(value)
                XCTAssertFalse(self.sut.isDataValid)
            default:
                XCTFail()
            }
            expectDidFail.fulfill()
        }

        let expectDidValidate = self.expectation(description: "Did validate")
        rawDataManagerDelegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid)
            XCTAssertTrue(errors!.first!.localizedDescription.starts(
                with: "[invalid-value] Invalid value 'nil' for key 'rawData' ")
            )
            expectDidValidate.fulfill()
        }

        sut.submit()

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

    var paymentResponseBodyWithRedirectAction: Response.Body.Payment {
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
                     requiredAction: .init(clientToken: MockAppState.mockClientTokenWithRedirect,
                                           name: .checkout,
                                           description: "description"),
                     status: .success,
                     paymentFailureReason: nil)
    }

    var paymentResponseAfterResume: Response.Body.Payment {
        .init(id: "id",
                     paymentId: "payment_id",
                     amount: 1234,
                     currencyCode: "GBP",
                     customer: nil,
                     customerId: "customer_id",
                     dateStr: nil,
                     order: nil,
                     orderId: "order_id",
                     requiredAction: nil,
                     status: .success,
                     paymentFailureReason: nil)
    }
}

private class MockXenditAPIClient: PrimerAPIClientXenditProtocol {
    
    var onListRetailOutlets: ((DecodedJWTToken, String) -> RetailOutletsList)?

    func listRetailOutlets(clientToken: DecodedJWTToken, paymentMethodId: String, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.RetailOutletsList>) {
        if let onListRetailOutlets = onListRetailOutlets {
            completion(.success(onListRetailOutlets(clientToken, paymentMethodId)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
}
