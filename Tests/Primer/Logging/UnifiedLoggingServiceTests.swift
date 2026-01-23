//
//  UnifiedLoggingServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class UnifiedLoggingServiceTests: XCTestCase {

    var mockNetworkClient: MockLogNetworkClient!
    var savedContainer: ContainerProtocol?

    override func setUp() async throws {
        try await super.setUp()

        // Save current container
        savedContainer = await DIContainer.current

        // Create fresh mock
        mockNetworkClient = MockLogNetworkClient()

        // Set up test container with mock logging service
        let testContainer = Container()
        try? await testContainer.register(LogNetworkClientProtocol.self)
            .asSingleton()
            .with { [mockNetworkClient] _ in mockNetworkClient! }

        try? await testContainer.register(SensitiveDataMasker.self)
            .asSingleton()
            .with { _ in SensitiveDataMasker() }

        try? await testContainer.register(LogPayloadBuilding.self)
            .asSingleton()
            .with { _ in LogPayloadBuilder() }

        try? await testContainer.register(LoggingService.self)
            .asSingleton()
            .with { resolver in
                LoggingService(
                    networkClient: try await resolver.resolve(LogNetworkClientProtocol.self),
                    payloadBuilder: try await resolver.resolve(LogPayloadBuilding.self),
                    masker: try await resolver.resolve(SensitiveDataMasker.self)
                )
            }

        await DIContainer.setContainer(testContainer)

        // Reset UnifiedLoggingService for fresh state
        await UnifiedLoggingService.shared.resetForTesting()

        // Initialize session context
        await LoggingSessionContext.shared.initialize(
            environment: .sandbox,
            sdkVersion: "2.41.0",
            clientSessionToken: "test-token",
            integrationType: .swiftUI
        )
    }

    override func tearDown() async throws {
        mockNetworkClient = nil

        // Restore original container
        if let savedContainer {
            await DIContainer.setContainer(savedContainer)
        } else {
            await DIContainer.clearContainer()
        }

        await UnifiedLoggingService.shared.resetForTesting()

        try await super.tearDown()
    }

    // MARK: - logErrorIfReportable Tests

    func test_logErrorIfReportable_sendsReportableError() async {
        let error = PrimerError.unknown(message: "Test error")

        await UnifiedLoggingService.shared.logErrorIfReportable(error, message: "Test message")

        // Give async operation time to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_logErrorIfReportable_skipsNonReportableError() async {
        let error = PrimerError.cancelled(paymentMethodType: "CARD")

        await UnifiedLoggingService.shared.logErrorIfReportable(error, message: "Test message")

        // Give async operation time to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 0)
    }

    func test_logErrorIfReportable_skipsPaymentFailedError() async {
        let error = PrimerError.paymentFailed(
            paymentMethodType: "CARD",
            paymentId: "pay_123",
            orderId: "order_123",
            status: "DECLINED"
        )

        await UnifiedLoggingService.shared.logErrorIfReportable(error, message: "Payment declined")

        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 0)
    }

    func test_logErrorIfReportable_sendsServerError() async {
        let error = InternalError.serverError(status: 500)

        await UnifiedLoggingService.shared.logErrorIfReportable(error, message: "Server error")

        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_logErrorIfReportable_worksWithoutMessage() async {
        // When no message is provided, it should auto-derive from error's plainDescription
        let error = PrimerError.unknown(message: "Test error")

        await UnifiedLoggingService.shared.logErrorIfReportable(error)

        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_logErrorIfReportable_usesAutoDerivedMessageFromError() async {
        // When no message is provided, LoggingService should extract from error
        let error = PrimerError.failedToCreatePayment(
            paymentMethodType: "CARD",
            description: "Payment API error"
        )

        await UnifiedLoggingService.shared.logErrorIfReportable(error)

        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    // MARK: - logInfo Tests

    func test_logInfo_sendsCheckoutInitializedEvent() async {
        await UnifiedLoggingService.shared.logInfo(
            message: "Checkout initialized (150ms)",
            event: "checkout-initialized",
            userInfo: ["init_duration_ms": 150]
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_logInfo_sendsEventWithoutUserInfo() async {
        await UnifiedLoggingService.shared.logInfo(
            message: "Checkout initialized",
            event: "checkout-initialized",
            userInfo: nil
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_logInfo_sendsEventWithCustomUserInfo() async {
        await UnifiedLoggingService.shared.logInfo(
            message: "Custom event",
            event: "custom-event",
            userInfo: ["custom_key": "custom_value", "numeric_key": 42]
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }
}
