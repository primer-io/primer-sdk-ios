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

        sut.start()

        let expectation = self.expectation(description: "Is cancelled")
        sut.didCancel = {
            expectation.fulfill()
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

    func testStartWithPreTokenizationAndContinue() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectDidStartTokenization = self.expectation(description: "onDidStartTokenization is called")
        delegate.onDidStartTokenization = { type in
            XCTAssertEqual(type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            expectDidStartTokenization.fulfill()
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

        sut.start()

        waitForExpectations(timeout: 60.0)
    }


}
