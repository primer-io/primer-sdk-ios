//
//  WebRedirectPaymentMethodTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 22/05/2024.
//

import XCTest
@testable import PrimerSDK

final class WebRedirectPaymentMethodTokenizationViewModelTests: XCTestCase {

    var tokenizationService: MockTokenizationService!

    var uiManager: MockPrimerUIManager!

    var sut: WebRedirectPaymentMethodTokenizationViewModel!

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        uiManager = MockPrimerUIManager()
        sut = WebRedirectPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.webRedirectPaymentMethod,
                                                            uiManager: uiManager,
                                                            tokenizationService: tokenizationService)
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    func testClientTokenValidation() throws {
        XCTAssertThrowsError(try sut.validate())

        try SDKSessionHelper.test {
            XCTAssertNoThrow(try sut.validate())
        }
    }

    func testStartWithCancellation() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        sut.start()

        let expectDidFail = self.expectation(description: "onDidFail called")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.cancelled(let paymentMethodType, _, _):
                XCTAssertEqual(paymentMethodType, Mocks.Static.Strings.webRedirectPaymentMethodType)
            default:
                XCTFail()
            }
            expectDidFail.fulfill()
        }

        let cancelNotif = Notification(name: Notification.Name.receivedUrlSchemeCancellation)
        NotificationCenter.default.post(cancelNotif)

        waitForExpectations(timeout: 2.0)
    }

    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp()
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

}
