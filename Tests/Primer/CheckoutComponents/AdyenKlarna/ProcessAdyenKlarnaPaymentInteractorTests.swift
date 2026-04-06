//
//  ProcessAdyenKlarnaPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ProcessAdyenKlarnaPaymentInteractorTests: XCTestCase {

    private var mockRepository: MockAdyenKlarnaRepository!
    private var sut: ProcessAdyenKlarnaPaymentInteractorImpl!

    override func setUp() {
        super.setUp()
        mockRepository = MockAdyenKlarnaRepository()

        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "testapp://payment")
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        // Use vault intent to skip PrimerDelegateProxy call that blocks without a delegate
        PrimerInternal.shared.intent = .vault

        sut = ProcessAdyenKlarnaPaymentInteractorImpl(
            repository: mockRepository,
            clientSessionActionsFactory: { StubClientSessionActions() }
        )
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - fetchPaymentOptions

    func test_fetchPaymentOptions_noConfig_throwsError() async {
        // Given - no API configuration set

        // When/Then
        do {
            _ = try await sut.fetchPaymentOptions()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockRepository.fetchPaymentOptionsCallCount, 0)
        }
    }

    func test_fetchPaymentOptions_withConfig_callsRepository() async throws {
        // Given
        SDKSessionHelper.setUp(
            withPaymentMethods: [makeAdyenKlarnaPaymentMethod()]
        )
        let expectedOptions = [
            AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later"),
            AdyenKlarnaPaymentOption(id: "pay_now", name: "Pay Now"),
        ]
        mockRepository.fetchPaymentOptionsResult = .success(expectedOptions)

        // When
        let options = try await sut.fetchPaymentOptions()

        // Then
        XCTAssertEqual(options, expectedOptions)
        XCTAssertEqual(mockRepository.fetchPaymentOptionsCallCount, 1)
    }

    // MARK: - execute

    func test_execute_completesFullFlow() async throws {
        // Given
        let option = AdyenKlarnaPaymentOption(id: "pay_later", name: "ADYEN_KLARNA_PAY_LATER")
        SDKSessionHelper.setUp(
            withPaymentMethods: [makeAdyenKlarnaPaymentMethod()]
        )

        // When
        let result = try await sut.execute(selectedOption: option)

        // Then
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
        XCTAssertEqual(mockRepository.lastTokenizeSessionInfo?.paymentMethodType, "ADYEN_KLARNA_PAY_LATER")
        XCTAssertEqual(mockRepository.openWebAuthCallCount, 1)
        XCTAssertEqual(mockRepository.pollCallCount, 1)
        XCTAssertEqual(mockRepository.resumePaymentCallCount, 1)
    }

    func test_execute_tokenizeFailure_throwsError() async {
        // Given
        let option = AdyenKlarnaPaymentOption(id: "pay_later", name: "ADYEN_KLARNA_PAY_LATER")
        SDKSessionHelper.setUp(
            withPaymentMethods: [makeAdyenKlarnaPaymentMethod()]
        )
        mockRepository.tokenizeResult = .failure(PrimerError.invalidValue(key: "test"))

        // When/Then
        do {
            _ = try await sut.execute(selectedOption: option)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
            XCTAssertEqual(mockRepository.openWebAuthCallCount, 0)
        }
    }

    func test_execute_pollFailure_throwsError() async {
        // Given
        let option = AdyenKlarnaPaymentOption(id: "pay_later", name: "ADYEN_KLARNA_PAY_LATER")
        SDKSessionHelper.setUp(
            withPaymentMethods: [makeAdyenKlarnaPaymentMethod()]
        )
        mockRepository.pollResult = .failure(PrimerError.cancelled(paymentMethodType: "ADYEN_KLARNA"))

        // When/Then
        do {
            _ = try await sut.execute(selectedOption: option)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockRepository.pollCallCount, 1)
            XCTAssertEqual(mockRepository.resumePaymentCallCount, 0)
        }
    }

    func test_execute_sessionInfo_containsCorrectLocaleAndPlatform() async throws {
        // Given
        let option = AdyenKlarnaPaymentOption(id: "slice_it", name: "ADYEN_KLARNA_SLICE_IT")
        SDKSessionHelper.setUp(
            withPaymentMethods: [makeAdyenKlarnaPaymentMethod()]
        )

        // When
        _ = try await sut.execute(selectedOption: option)

        // Then
        let sessionInfo = mockRepository.lastTokenizeSessionInfo
        XCTAssertNotNil(sessionInfo)
        XCTAssertEqual(sessionInfo?.platform, "IOS")
        XCTAssertEqual(sessionInfo?.paymentMethodType, "ADYEN_KLARNA_SLICE_IT")
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

// MARK: - Stub

private final class StubClientSessionActions: ClientSessionActionsProtocol {
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws {}
    func unselectPaymentMethodIfNeeded() async throws {}
    func dispatch(actions: [ClientSession.Action]) async throws {}
}
