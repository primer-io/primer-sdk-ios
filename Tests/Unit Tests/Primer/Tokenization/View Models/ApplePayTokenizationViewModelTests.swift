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

        let appState = MockAppState()
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
        SDKSessionHelper.tearDown()
        XCTAssertThrowsError(try sut.validate())

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    delegate.paymentAuthorizationController?(PKPaymentAuthorizationController(),
                                                             didAuthorizePayment: MockPKPayment(),
                                                             handler: { _ in })
                }
                expectDidPresent.fulfill()
                seal.fulfill()
            }
        }

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { body in
            expectDidTokenize.fulfill()
            return Promise.fulfilled(.init(analyticsId: "analytics_id",
                                           id: "id",
                                           isVaulted: false,
                                           isAlreadyVaulted: false,
                                           paymentInstrumentType: .offSession,
                                           paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
                                           paymentInstrumentData: nil,
                                           threeDSecureAuthentication: nil,
                                           token: "token",
                                           tokenType: .singleUse,
                                           vaultData: nil))
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { body in
            expectDidCreatePayment.fulfill()
            return .init(id: "id",
                         paymentId: "payment_id",
                         amount: 123,
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

}

fileprivate class MockApplePayPresentationManager: ApplePayPresenting {
    var isPresentable: Bool = true

    var onPresent: ((ApplePayRequest, PKPaymentAuthorizationControllerDelegate) -> Promise<Void>)?

    func present(withRequest applePayRequest: ApplePayRequest, delegate: PKPaymentAuthorizationControllerDelegate) -> Promise<Void> {
        return onPresent?(applePayRequest, delegate) ?? Promise.rejected(PrimerError.generic(message: "", userInfo: nil, diagnosticsId: ""))
    }
    

}

fileprivate class MockPKPayment: PKPayment {
    override var token: PKPaymentToken {
        return MockPKPaymentToken()
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
