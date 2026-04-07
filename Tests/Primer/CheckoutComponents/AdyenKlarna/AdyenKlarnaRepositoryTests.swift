//
//  AdyenKlarnaRepositoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class AdyenKlarnaRepositoryTests: XCTestCase {

    private var mockAPIClient: MockPrimerAPIClient!
    private var sut: AdyenKlarnaRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockPrimerAPIClient()

        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "testapp://payment")
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        sut = AdyenKlarnaRepositoryImpl(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - fetchPaymentOptions

    func test_fetchPaymentOptions_success_returnsOptions() async throws {
        // Given
        let response = AdyenKlarnaPaymentOptionsResponse(result: [
            AdyenKlarnaPaymentOptionDTO(id: "pay_later", name: "Pay Later"),
            AdyenKlarnaPaymentOptionDTO(id: "pay_now", name: "Pay Now"),
        ])
        mockAPIClient.listAdyenKlarnaPaymentTypesResult = (response, nil)
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])

        // When
        let options = try await sut.fetchPaymentOptions(configId: "test-config-id")

        // Then
        XCTAssertEqual(options.count, 2)
        XCTAssertEqual(options[0].id, "pay_later")
        XCTAssertEqual(options[0].name, "Pay Later")
        XCTAssertEqual(options[1].id, "pay_now")
        XCTAssertEqual(options[1].name, "Pay Now")
    }

    func test_fetchPaymentOptions_noClientToken_throwsError() async {
        // Given - no JWT token set

        // When/Then
        do {
            _ = try await sut.fetchPaymentOptions(configId: "test-config-id")
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case .invalidClientToken = error {
                // Expected
            } else {
                XCTFail("Expected invalidClientToken error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetchPaymentOptions_apiError_throws() async {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])
        mockAPIClient.listAdyenKlarnaPaymentTypesResult = (nil, NSError(domain: "test", code: 1))

        // When/Then
        do {
            _ = try await sut.fetchPaymentOptions(configId: "test-config-id")
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func test_fetchPaymentOptions_emptyResult_returnsEmptyArray() async throws {
        // Given
        let response = AdyenKlarnaPaymentOptionsResponse(result: [])
        mockAPIClient.listAdyenKlarnaPaymentTypesResult = (response, nil)
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])

        // When
        let options = try await sut.fetchPaymentOptions(configId: "test-config-id")

        // Then
        XCTAssertTrue(options.isEmpty)
    }

    // MARK: - tokenize

    func test_tokenize_noPaymentMethodConfig_throwsError() async {
        // Given - no API configuration
        let sessionInfo = AdyenKlarnaSessionInfo(locale: "en", paymentMethodType: "PAY_LATER")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_KLARNA", sessionInfo: sessionInfo)
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case let .invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "paymentMethodType")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - resumePayment

    func test_resumePayment_withoutPriorTokenization_throwsError() async {
        // Given - no tokenize call made

        // When/Then
        do {
            _ = try await sut.resumePayment(paymentMethodType: "ADYEN_KLARNA", resumeToken: "token")
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

    // MARK: - cancelPolling

    func test_cancelPolling_doesNotCrash() {
        // When/Then - should not crash even without active polling
        sut.cancelPolling(paymentMethodType: "ADYEN_KLARNA")
    }

    // MARK: - Helpers

    private func makeAdyenKlarnaPaymentMethod() -> PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "adyen-klarna-config-id",
            implementationType: .nativeSdk,
            type: "ADYEN_KLARNA",
            name: "Adyen Klarna",
            processorConfigId: "adyen-klarna-processor",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
    }
}
