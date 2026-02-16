//
//  WebRedirectRepositoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class WebRedirectRepositoryTests: XCTestCase {

    private var sut: WebRedirectRepositoryImpl!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - resumePayment Tests

    func test_resumePayment_withoutPriorTokenization_throwsError() async {
        // Given - no tokenize call made, so no payment ID stored
        sut = WebRedirectRepositoryImpl(
            tokenizationService: MockTokenizationService(),
            webAuthService: MockWebAuthenticationService(),
            createPaymentService: MockCreateResumePaymentService()
        )

        // When/Then
        do {
            _ = try await sut.resumePayment(paymentMethodType: "ADYEN_SOFORT", resumeToken: "token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: let reason, diagnosticsId: _) = error {
                XCTAssertEqual(key, "resumePaymentId")
                XCTAssertTrue(reason?.contains("Tokenization must be called first") ?? false)
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

}
