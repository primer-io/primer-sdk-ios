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

    // MARK: - openWebAuthentication URL Scheme Tests

    func test_openWebAuthentication_withHttpsUrl_usesWebAuthService() async throws {
        // Given
        let mockWebAuthService = MockWebAuthenticationService()
        let expectedCallbackUrl = URL(string: "myapp://callback")!
        mockWebAuthService.onConnect = { _, _ in expectedCallbackUrl }

        sut = WebRedirectRepositoryImpl(
            tokenizationService: MockTokenizationService(),
            webAuthService: mockWebAuthService,
            createPaymentService: MockCreateResumePaymentService()
        )

        // Set up valid URL scheme in settings (must include "://")
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "myapp://")
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let httpsUrl = URL(string: "https://bank.example.com/auth")!

        // When
        let result = try await sut.openWebAuthentication(paymentMethodType: "ADYEN_SOFORT", url: httpsUrl)

        // Then
        XCTAssertEqual(result, expectedCallbackUrl)
    }
}
