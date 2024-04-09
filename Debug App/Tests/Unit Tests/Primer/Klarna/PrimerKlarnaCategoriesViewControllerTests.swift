//
//  PrimerKlarnaCategoriesViewControllerTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 18.03.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class PrimerKlarnaCategoriesViewControllerTests: XCTestCase {

    var sut: PrimerKlarnaCategoriesViewController!
    var mockDelegate: MockPrimerKlarnaCategoriesDelegate!

    override func setUp() {
        super.setUp()
        mockDelegate = MockPrimerKlarnaCategoriesDelegate()
        let paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod
        let tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
        sut = PrimerKlarnaCategoriesViewController(tokenizationComponent: tokenizationComponent, delegate: mockDelegate)
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        mockDelegate = nil
        sut = nil
        super.tearDown()
    }

    func test_sessionCompleted() {
        let authToken = "auth-token"
        sut.sessionFinished(with: authToken)

        XCTAssertEqual(mockDelegate.sessionCompleted, true)
        XCTAssertEqual(mockDelegate.authorizationTokenReceived, authToken)
    }

    func test_sessionFailed() {
        let error = PrimerError.failedToCreateSession(error: nil, userInfo: [:], diagnosticsId: UUID().uuidString)
        sut.didReceiveError(error: error)

        let errorReceived = mockDelegate.errorReceived as? PrimerError

        XCTAssertEqual(mockDelegate.sessionFailed, true)
        XCTAssertEqual(errorReceived?.diagnosticsId, error.diagnosticsId)
    }
}

class MockPrimerKlarnaCategoriesDelegate: PrimerKlarnaCategoriesDelegate {
    var sessionCompleted = false
    var sessionFailed = false
    var authorizationTokenReceived: String?
    var errorReceived: Error?

    func primerKlarnaPaymentSessionCompleted(authorizationToken: String) {
        sessionCompleted = true
        authorizationTokenReceived = authorizationToken
    }

    func primerKlarnaPaymentSessionFailed(error: Error) {
        sessionFailed = true
        errorReceived = error
    }
}
#endif
