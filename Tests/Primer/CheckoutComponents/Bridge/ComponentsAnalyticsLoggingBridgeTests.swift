//
//  ComponentsAnalyticsLoggingBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@_spi(PrimerInternal) @testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class ComponentsAnalyticsLoggingBridgeTests: XCTestCase {

    private var sut: ComponentsAnalyticsLoggingBridge!
    private var mockAnalyticsService: MockBridgeAnalyticsService!
    private var mockAnalyticsInteractor: MockTrackingAnalyticsInteractor!
    private var mockLoggingService: MockBridgeLoggingService!
    private var mockConfigurationModule: MockBridgeConfigurationModule!

    override func setUp() async throws {
        try await super.setUp()
        mockAnalyticsService = MockBridgeAnalyticsService()
        mockAnalyticsInteractor = MockTrackingAnalyticsInteractor()
        mockLoggingService = MockBridgeLoggingService()
        mockConfigurationModule = MockBridgeConfigurationModule()

        sut = ComponentsAnalyticsLoggingBridge(
            analyticsService: mockAnalyticsService,
            analyticsInteractor: mockAnalyticsInteractor,
            loggingService: mockLoggingService,
            configurationModule: mockConfigurationModule
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockAnalyticsService = nil
        mockAnalyticsInteractor = nil
        mockLoggingService = nil
        mockConfigurationModule = nil
        try await super.tearDown()
    }

    // MARK: - Setup Tests

    func test_setup_initializesAnalyticsWithConfig() async {
        // Given
        let config = AnalyticsSessionConfig(
            environment: .sandbox,
            checkoutSessionId: "cs_test_123",
            clientSessionId: "client_test_456",
            primerAccountId: "acc_test_789",
            sdkVersion: "2.46.7",
            clientSessionToken: "test_token"
        )
        mockConfigurationModule.configToReturn = config

        // When
        await sut.setup(clientToken: "test-token")

        // Then
        let initConfig = await mockAnalyticsService.initializeConfig
        XCTAssertNotNil(initConfig)
        XCTAssertEqual(initConfig?.checkoutSessionId, config.checkoutSessionId)
        XCTAssertEqual(initConfig?.clientSessionId, config.clientSessionId)
    }

    func test_setup_withNilConfig_doesNotInitializeAnalytics() async {
        // Given
        mockConfigurationModule.configToReturn = nil

        // When
        await sut.setup(clientToken: "test-token")

        // Then
        let initConfig = await mockAnalyticsService.initializeConfig
        XCTAssertNil(initConfig)
    }

    // MARK: - Track Event Tests

    func test_trackEvent_validEvent_tracksViaInteractor() async {
        // When
        await sut.trackEvent("SDK_INIT_START", metadata: nil)

        // Then
        let hasTracked = await mockAnalyticsInteractor.hasTracked(.sdkInitStart)
        XCTAssertTrue(hasTracked)
    }

    func test_trackEvent_unknownEvent_silentlyIgnored() async {
        // When
        await sut.trackEvent("UNKNOWN_EVENT", metadata: nil)

        // Then
        let count = await mockAnalyticsInteractor.trackEventCallCount
        XCTAssertEqual(count, 0)
    }

    func test_trackEvent_allEventTypes_trackedCorrectly() async {
        // When
        for eventType in AnalyticsEventType.allCases {
            await sut.trackEvent(eventType.rawValue, metadata: nil)
        }

        // Then
        let count = await mockAnalyticsInteractor.trackEventCallCount
        XCTAssertEqual(count, AnalyticsEventType.allCases.count)
    }

    func test_trackEvent_vaultEvent_tracksViaInteractor() async {
        // When
        await sut.trackEvent("VAULT_METHOD_DELETED", metadata: ["vaultedMethodId": "vm-1"])

        // Then
        let hasTracked = await mockAnalyticsInteractor.hasTracked(.vaultMethodDeleted)
        XCTAssertTrue(hasTracked)
    }

    // MARK: - Metadata Mapping Tests

    func test_mapMetadata_nilMetadata_returnsGeneral() {
        XCTAssertNil(ComponentsAnalyticsLoggingBridge.mapMetadata(nil, for: .sdkInitStart).paymentMethod)
    }

    func test_mapMetadata_emptyMetadata_returnsGeneral() {
        XCTAssertNil(ComponentsAnalyticsLoggingBridge.mapMetadata([:], for: .sdkInitStart).paymentMethod)
    }

    func test_mapMetadata_noPaymentMethod_returnsGeneral() {
        XCTAssertNil(
            ComponentsAnalyticsLoggingBridge.mapMetadata(
                ["someKey": "someValue"], for: .checkoutFlowStarted
            ).paymentMethod
        )
    }

    func test_mapMetadata_paymentMethodOnly_returnsPayment() {
        // When
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata(
            ["paymentMethod": "PAYMENT_CARD"], for: .paymentSubmitted
        )

        // Then
        XCTAssertEqual(result.paymentMethod, "PAYMENT_CARD")
        XCTAssertNil(result.paymentId)
        XCTAssertNil(result.threedsProvider)
        XCTAssertNil(result.redirectDestinationUrl)
    }

    func test_mapMetadata_paymentMethodWithPaymentId_returnsPayment() {
        // When
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
            "paymentMethod": "PAYMENT_CARD",
            "paymentId": "pay_123",
        ], for: .paymentSuccess)

        // Then
        XCTAssertEqual(result.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(result.paymentId, "pay_123")
    }

    func test_mapMetadata_withThreedsProvider_returnsThreeDS() {
        // When
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
            "paymentMethod": "PAYMENT_CARD",
            "threedsProvider": "ADYEN",
        ], for: .paymentThreeds)

        // Then
        XCTAssertEqual(result.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(result.threedsProvider, "ADYEN")
    }

    func test_mapMetadata_withRedirectUrl_returnsRedirect() {
        // When
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
            "paymentMethod": "PAYPAL",
            "redirectDestinationUrl": "https://paypal.com/checkout",
        ], for: .paymentRedirectToThirdParty)

        // Then
        XCTAssertEqual(result.paymentMethod, "PAYPAL")
        XCTAssertEqual(result.redirectDestinationUrl, "https://paypal.com/checkout")
    }

    func test_mapMetadata_threedsHasPriorityOverRedirect() {
        // When — both threedsProvider and redirectDestinationUrl present
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
            "paymentMethod": "PAYMENT_CARD",
            "threedsProvider": "ADYEN",
            "redirectDestinationUrl": "https://example.com",
        ], for: .paymentThreeds)

        // Then — threeDS takes priority
        XCTAssertEqual(result.threedsProvider, "ADYEN")
        XCTAssertNil(result.redirectDestinationUrl)
    }

    // MARK: - Vault Metadata Mapping Tests

    func test_mapMetadata_vaultEvent_mapsAllFields() {
        // When
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
            "vaultedMethodId": "vm-1",
            "previousVaultedMethodId": "vm-0",
            "promotedVaultedMethodId": "vm-2",
            "isActive": "true",
            "vaultedMethodCount": "3",
            "exitedFromConfirmation": "false",
            "network": "VISA",
            "expectedCvvLength": "4",
            "errorId": "vault-delete-failed",
        ], for: .vaultMethodDeleted)

        // Then
        let vault = result.vaultEvent
        XCTAssertEqual(vault?.vaultedMethodId, "vm-1")
        XCTAssertEqual(vault?.previousVaultedMethodId, "vm-0")
        XCTAssertEqual(vault?.promotedVaultedMethodId, "vm-2")
        XCTAssertEqual(vault?.isActive, true)
        XCTAssertEqual(vault?.vaultedMethodCount, 3)
        XCTAssertEqual(vault?.exitedFromConfirmation, false)
        XCTAssertEqual(vault?.network, "VISA")
        XCTAssertEqual(vault?.expectedCvvLength, 4)
        XCTAssertEqual(vault?.errorId, "vault-delete-failed")
    }

    func test_mapMetadata_vaultEvent_emptyStringsBecomeNil() {
        // When — RN sends empty strings for absent values
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata(
            ["vaultedMethodId": "", "network": ""], for: .vaultCvvSubmitted
        )

        // Then
        XCTAssertNotNil(result.vaultEvent)
        XCTAssertNil(result.vaultEvent?.vaultedMethodId)
        XCTAssertNil(result.vaultEvent?.network)
    }

    func test_mapMetadata_vaultEvent_malformedNumbersAndBools_becomeNil() {
        // When — RN must send "true"/"false" and plain integers; anything else degrades to nil
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
            "vaultedMethodId": "vm-1",
            "isActive": "1",
            "exitedFromConfirmation": "True",
            "vaultedMethodCount": "3.5",
            "expectedCvvLength": "notanint",
        ], for: .vaultMethodDeleted)

        // Then — event still maps to vault, malformed fields dropped
        XCTAssertEqual(result.vaultEvent?.vaultedMethodId, "vm-1")
        XCTAssertNil(result.vaultEvent?.isActive)
        XCTAssertNil(result.vaultEvent?.exitedFromConfirmation)
        XCTAssertNil(result.vaultEvent?.vaultedMethodCount)
        XCTAssertNil(result.vaultEvent?.expectedCvvLength)
    }

    func test_mapMetadata_vaultEvent_nilMetadata_returnsEmptyVault() {
        // When
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata(nil, for: .vaultListOpened)

        // Then
        XCTAssertNotNil(result.vaultEvent)
        XCTAssertNil(result.vaultEvent?.vaultedMethodId)
    }

    func test_mapMetadata_vaultEvent_neverMapsToPayment() {
        // When — a stray paymentMethod key must not turn a vault event into payment metadata
        let result = ComponentsAnalyticsLoggingBridge.mapMetadata(
            ["paymentMethod": "PAYMENT_CARD", "vaultedMethodId": "vm-1"],
            for: .vaultDeletionRequested
        )

        // Then
        XCTAssertNil(result.paymentMethod)
        XCTAssertEqual(result.vaultEvent?.vaultedMethodId, "vm-1")
    }

    // MARK: - Vault Payload Encoding Tests

    func test_buildPayload_vaultEvent_encodesVaultWireKeys() throws {
        // Given
        let config = AnalyticsSessionConfig(
            environment: .sandbox,
            checkoutSessionId: "cs-1",
            clientSessionId: "cls-1",
            primerAccountId: "acc-1",
            sdkVersion: "3.0.0",
            clientSessionToken: "token"
        )

        // When
        let payload = AnalyticsPayloadBuilder().buildPayload(
            eventType: .vaultMethodDeleted,
            metadata: .vault(VaultEvent(vaultedMethodId: "vm-1", promotedVaultedMethodId: "vm-2", isActive: true)),
            config: config
        )
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any]
        )

        // Then — wire keys stay camelCase with native JSON types, absent fields omitted
        XCTAssertEqual(json["eventName"] as? String, "VAULT_METHOD_DELETED")
        XCTAssertEqual(json["vaultedMethodId"] as? String, "vm-1")
        XCTAssertEqual(json["promotedVaultedMethodId"] as? String, "vm-2")
        XCTAssertEqual(json["isActive"] as? Bool, true)
        XCTAssertNil(json["vaultedMethodCount"])
        XCTAssertNil(json["expectedCvvLength"])
        XCTAssertNil(json["paymentMethod"])
    }

    // MARK: - Log Info Tests

    func test_logInfo_delegatesToLoggingService() async {
        // When
        await sut.logInfo(message: "test message", event: "SDK_INIT")

        // Then
        let calls = await mockLoggingService.logInfoCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.message, "test message")
        XCTAssertEqual(calls.first?.event, "SDK_INIT")
    }

    // MARK: - Log Error Tests

    func test_logError_delegatesToLoggingService() async {
        // When
        await sut.logError(
            message: "Payment failed",
            event: "failed-payment",
            errorMessage: "Network request failed",
            stack: "at Checkout.pay()"
        )

        // Then
        let calls = await mockLoggingService.logErrorCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.message, "Payment failed")
        XCTAssertEqual(calls.first?.event, "failed-payment")
        XCTAssertEqual(calls.first?.errorMessage, "Network request failed")
        XCTAssertEqual(calls.first?.stack, "at Checkout.pay()")
    }

    func test_logError_defaultsOptionalsToNil() async {
        // When
        await sut.logError(message: "boom")

        // Then
        let calls = await mockLoggingService.logErrorCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.message, "boom")
        XCTAssertNil(calls.first?.event)
        XCTAssertNil(calls.first?.errorMessage)
        XCTAssertNil(calls.first?.stack)
    }

}

// MARK: - Mocks

@available(iOS 15.0, *)
private final actor MockBridgeAnalyticsService: CheckoutComponentsAnalyticsServiceProtocol {
    private(set) var initializeConfig: AnalyticsSessionConfig?
    private(set) var sentEvents: [(eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?)] = []

    func initialize(config: AnalyticsSessionConfig) async {
        initializeConfig = config
    }

    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        sentEvents.append((eventType: eventType, metadata: metadata))
    }
}

@available(iOS 15.0, *)
private final actor MockBridgeLoggingService: ComponentsLoggingServiceProtocol {
    struct InfoCall {
        let message: String
        let event: String
        let userInfo: [String: Any]?
    }

    struct ErrorCall {
        let message: String
        let event: String?
        let errorMessage: String?
        let stack: String?
        let userInfo: [String: Any]?
    }

    private(set) var logInfoCalls: [InfoCall] = []
    private(set) var logErrorCalls: [ErrorCall] = []

    func logInfo(message: String, event: String, userInfo: [String: Any]?) async {
        logInfoCalls.append(InfoCall(message: message, event: event, userInfo: userInfo))
    }

    func logError(
        message: String,
        event: String?,
        errorMessage: String?,
        stack: String?,
        userInfo: [String: Any]?
    ) async {
        logErrorCalls.append(
            ErrorCall(
                message: message,
                event: event,
                errorMessage: errorMessage,
                stack: stack,
                userInfo: userInfo
            )
        )
    }
}

@available(iOS 15.0, *)
private final class MockBridgeConfigurationModule: AnalyticsSessionConfigProviding {
    var configToReturn: AnalyticsSessionConfig?

    func makeAnalyticsSessionConfig(
        checkoutSessionId: String,
        clientToken: String,
        sdkVersion: String
    ) -> AnalyticsSessionConfig? {
        configToReturn
    }
}
