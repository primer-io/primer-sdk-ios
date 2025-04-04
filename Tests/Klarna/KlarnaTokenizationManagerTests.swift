//
//  KlarnaTokenizationManagerTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 05.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaTokenizationManagerTests: XCTestCase {

    var sut: KlarnaTokenizationManager!
    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!

    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp(order: KlarnaTestsMocks.klarnaOrder)
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        sut = KlarnaTokenizationManager(tokenizationService: tokenizationService, createResumePaymentService: createResumePaymentService)
    }

    override func tearDown() {
        sut = nil
        createResumePaymentService = nil
        tokenizationService = nil

        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    func test_tokenizeHeadless_success() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Promise.fulfilled(KlarnaTestsMocks.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return KlarnaTestsMocks.paymentResponseBody
        }

        firstly {
            sut.tokenizeHeadless(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectDidCreatePayment,
            expectation
        ], timeout: 30.0, enforceOrder: true)
    }

    func test_tokenizeHeadless_failure() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Promise.rejected(PrimerError.unknown(userInfo: .errorUserInfoDictionary(), diagnosticsId: UUID().uuidString))
        }

        firstly {
            sut.tokenizeHeadless(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        .catch { error in
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_tokenizeDropIn_success() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Promise.fulfilled(KlarnaTestsMocks.tokenizationResponseBody)
        }

        firstly {
            sut.tokenizeDropIn(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_tokenizeDropIn_failure() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Promise.rejected(PrimerError.unknown(userInfo: .errorUserInfoDictionary(), diagnosticsId: UUID().uuidString))
        }

        firstly {
            sut.tokenizeDropIn(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        .catch { error in
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_tokenizeHeadless_maunualHandling_success() {
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")

        let settings = PrimerSettings(paymentHandling: .manual)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Promise.fulfilled(KlarnaTestsMocks.tokenizationResponseBody)
        }

        let expectOnDidTokenizePaymentMethod = self.expectation(description: "onDidTokenizePaymentMethod is called")
        delegate.onDidTokenizePaymentMethod = { data, decision in
            XCTAssertEqual(data.paymentMethodType, "KLARNA")
            decision(.complete())
            expectOnDidTokenizePaymentMethod.fulfill()
        }

        firstly {
            sut.tokenizeHeadless(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectOnDidTokenizePaymentMethod,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

}

extension KlarnaTokenizationManagerTests {

    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken(
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }

    private func getErrorUserInfo() -> [String: String] {
        return [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ]
    }
}

#endif
