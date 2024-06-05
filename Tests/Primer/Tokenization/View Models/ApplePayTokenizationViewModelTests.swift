//
//  ApplePayTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 23/05/2024.
//

import XCTest
import PassKit
@testable import PrimerSDK

final class ApplePayTokenizationViewModelTests: XCTestCase {

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var uiManager: MockPrimerUIManager!

    var appState: MockAppState!

    var sut: ApplePayTokenizationViewModel!

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        sut = ApplePayTokenizationViewModel(config: Mocks.PaymentMethods.webRedirectPaymentMethod,
                                            uiManager: uiManager,
                                            tokenizationService: tokenizationService,
                                            createResumePaymentService: createResumePaymentService)

        let settings = PrimerSettings(paymentMethodOptions:
            PrimerPaymentMethodOptions(applePayOptions:
                PrimerApplePayOptions(merchantIdentifier: "merchant_id", merchantName: "merchant_name")
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        appState = MockAppState()
        appState.amount = 1234
        appState.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(appState as AppStateProtocol)
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    func testClientTokenValidation() throws {
        // without token
        SDKSessionHelper.tearDown()
        XCTAssertThrowsError(try sut.validate())

        // without order
        try SDKSessionHelper.test {
            XCTAssertThrowsError(try sut.validate())
        }

        // without currency
        try SDKSessionHelper.test(order: order) {
            appState.currency = nil
            XCTAssertThrowsError(try sut.validate())
            appState.currency = Currency(code: "GBP", decimalDigits: 2)
        }

        // without apple pay options
        try SDKSessionHelper.test(order: order) {
            let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
            DependencyContainer.register(settings as PrimerSettingsProtocol)
            XCTAssertThrowsError(try sut.validate())
            let resetSettings = PrimerSettings(paymentMethodOptions:
                PrimerPaymentMethodOptions(applePayOptions:
                    PrimerApplePayOptions(merchantIdentifier: "merchant_id", merchantName: "merchant_name")
                )
            )
            DependencyContainer.register(resetSettings as PrimerSettingsProtocol)
        }

        // with order
        try SDKSessionHelper.test(order: order) {
            XCTAssertNoThrow(try sut.validate())
        }
    }

    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp(order: order)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
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

        waitForExpectations(timeout: 2.0)
    }

    func testStartWithFullCheckoutFlow() throws {
        SDKSessionHelper.setUp(order: order)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let applePayPresentationManager = MockApplePayPresentationManager()
        sut.applePayPresentationManager = applePayPresentationManager

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectCheckoutDidCompletewithData = self.expectation(description: "")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectCheckoutDidCompletewithData.fulfill()
        }

        let expectDidPresent = self.expectation(description: "Did present ApplePay")
        applePayPresentationManager.onPresent = { request, delegate in
            Promise { seal in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    let dummyController = PKPaymentAuthorizationController()
                    delegate.paymentAuthorizationController?(dummyController,
                                                             didAuthorizePayment: MockPKPayment(),
                                                             handler: { _ in })
                    delegate.paymentAuthorizationControllerDidFinish(dummyController)
                }
                expectDidPresent.fulfill()
                seal.fulfill()
            }
        }

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { body in
            expectDidTokenize.fulfill()
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

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectDidPresent,
            expectDidTokenize,
            expectDidCreatePayment,
            expectCheckoutDidCompletewithData
        ], timeout: 10.0, enforceOrder: true)
    }

    // MARK: Helpers

    var order: ClientSession.Order {
        .init(id: "order_id",
              merchantAmount: 1234,
              totalOrderAmount: 1234,
              totalTaxAmount: nil,
              countryCode: .gb,
              currencyCode: Currency(code: "GBP", decimalDigits: 2),
              fees: nil,
              lineItems: [
                .init(itemId: "item_id",
                      quantity: 1,
                      amount: 1234,
                      discountAmount: nil,
                      name: "my_item", 
                      description: "item_description",
                      taxAmount: nil,
                      taxCode: nil,
                      productType: nil)
              ],
              shippingAmount: nil)
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

}

fileprivate class MockApplePayPresentationManager: ApplePayPresenting {
    var isPresentable: Bool = true

    var onPresent: ((ApplePayRequest, PKPaymentAuthorizationControllerDelegate) -> Promise<Void>)?

    func present(withRequest applePayRequest: ApplePayRequest, delegate: PKPaymentAuthorizationControllerDelegate) -> Promise<Void> {
        return onPresent?(applePayRequest, delegate) ?? Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }
    

}

fileprivate class MockPKPayment: PKPayment {
    override var token: PKPaymentToken {
        return MockPKPaymentToken()
    }

    override var billingContact: PKContact? {
        return MockPKContact()
    }
}

fileprivate class MockPKPaymentToken: PKPaymentToken {
    override var paymentMethod: PKPaymentMethod {
        return MockPKPaymentMethod()
    }

    override var paymentData: Data {
        let response = ApplePayPaymentResponseTokenPaymentData(data: "data", 
                                                               signature: "sig",
                                                               version: "version",
                                                               header: .init(ephemeralPublicKey: "key", publicKeyHash: "hash", transactionId: "t_id"))
        return try! JSONEncoder().encode(response)
    }
}

fileprivate class MockPKPaymentMethod: PKPaymentMethod {
    override var network: PKPaymentNetwork? {
        .visa
    }

    override var displayName: String? {
        "display_name"
    }

    override var type: PKPaymentMethodType {
        .credit
    }
}

fileprivate class MockPKContact: PKContact {
    override var postalAddress: CNPostalAddress? {
        get {
            let address = CNMutablePostalAddress()
            address.street = "pk_contact_street"
            address.postalCode = "pk_contact_postal_code"
            address.city = "pk_contact_city"
            address.state = "pk_contact_state"
            return address as CNPostalAddress
        }
        set {}
    }
}
