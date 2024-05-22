//
//  WebRedirectPaymentMethodTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 22/05/2024.
//

import XCTest
@testable import PrimerSDK

final class WebRedirectPaymentMethodTokenizationViewModelTests: XCTestCase {

    var uiManager: MockPrimerUIManager!

    var sut: WebRedirectPaymentMethodTokenizationViewModel!

    override func setUpWithError() throws {
        uiManager = MockPrimerUIManager()
        sut = WebRedirectPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.webRedirectPaymentMethod,
                                                            uiManager: uiManager)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testClientTokenValidation() throws {
        XCTAssertThrowsError(try sut.validate())

        try SDKSessionHelper.test {
            XCTAssertNoThrow(try sut.validate())
        }
    }

    func testStartWithCancellation() throws {
        sut.start()

        let expectation = self.expectation(description: "Is cancelled")
        sut.didCancel = {
            expectation.fulfill()
        }

        let cancelNotif = Notification(name: Notification.Name.receivedUrlSchemeCancellation)
        NotificationCenter.default.post(cancelNotif)

        waitForExpectations(timeout: 2.0)
    }

}
