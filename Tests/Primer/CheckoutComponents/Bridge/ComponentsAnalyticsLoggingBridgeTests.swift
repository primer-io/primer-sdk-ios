//
//  ComponentsAnalyticsLoggingBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@_spi(PrimerInternal) @testable import PrimerSDK

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
    let config = makeTestConfig()
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
    // Given
    let eventNames = [
      "SDK_INIT_START", "SDK_INIT_END", "CHECKOUT_FLOW_STARTED",
      "PAYMENT_METHOD_SELECTION", "PAYMENT_DETAILS_ENTERED", "PAYMENT_SUBMITTED",
      "PAYMENT_PROCESSING_STARTED", "PAYMENT_REDIRECT_TO_THIRD_PARTY", "PAYMENT_THREEDS",
      "PAYMENT_SUCCESS", "PAYMENT_FAILURE", "PAYMENT_REATTEMPTED", "PAYMENT_FLOW_EXITED",
    ]

    // When
    for name in eventNames {
      await sut.trackEvent(name, metadata: nil)
    }

    // Then
    let count = await mockAnalyticsInteractor.trackEventCallCount
    XCTAssertEqual(count, 13)
  }

  // MARK: - Metadata Mapping Tests

  func test_mapMetadata_nilMetadata_returnsGeneral() {
    let result = ComponentsAnalyticsLoggingBridge.mapMetadata(nil)
    assertIsGeneral(result)
  }

  func test_mapMetadata_emptyMetadata_returnsGeneral() {
    let result = ComponentsAnalyticsLoggingBridge.mapMetadata([:])
    assertIsGeneral(result)
  }

  func test_mapMetadata_noPaymentMethod_returnsGeneral() {
    let result = ComponentsAnalyticsLoggingBridge.mapMetadata(["someKey": "someValue"])
    assertIsGeneral(result)
  }

  func test_mapMetadata_paymentMethodOnly_returnsPayment() {
    // When
    let result = ComponentsAnalyticsLoggingBridge.mapMetadata(["paymentMethod": "PAYMENT_CARD"])

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
    ])

    // Then
    XCTAssertEqual(result.paymentMethod, "PAYMENT_CARD")
    XCTAssertEqual(result.paymentId, "pay_123")
  }

  func test_mapMetadata_withThreedsProvider_returnsThreeDS() {
    // When
    let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
      "paymentMethod": "PAYMENT_CARD",
      "threedsProvider": "ADYEN",
    ])

    // Then
    XCTAssertEqual(result.paymentMethod, "PAYMENT_CARD")
    XCTAssertEqual(result.threedsProvider, "ADYEN")
  }

  func test_mapMetadata_withRedirectUrl_returnsRedirect() {
    // When
    let result = ComponentsAnalyticsLoggingBridge.mapMetadata([
      "paymentMethod": "PAYPAL",
      "redirectDestinationUrl": "https://paypal.com/checkout",
    ])

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
    ])

    // Then — threeDS takes priority
    XCTAssertEqual(result.threedsProvider, "ADYEN")
    XCTAssertNil(result.redirectDestinationUrl)
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

  // MARK: - Helpers

  private func makeTestConfig() -> AnalyticsSessionConfig {
    AnalyticsSessionConfig(
      environment: .sandbox,
      checkoutSessionId: "cs_test_123",
      clientSessionId: "client_test_456",
      primerAccountId: "acc_test_789",
      sdkVersion: "2.46.7",
      clientSessionToken: "test_token"
    )
  }

  private func assertIsGeneral(_ metadata: AnalyticsEventMetadata, file: StaticString = #filePath,
                                line: UInt = #line) {
    if case .general = metadata { return }
    XCTFail("Expected .general but got \(metadata)", file: file, line: line)
  }
}

// MARK: - Mocks

@available(iOS 15.0, *)
private actor MockBridgeAnalyticsService: CheckoutComponentsAnalyticsServiceProtocol {
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
private actor MockBridgeLoggingService: ComponentsLoggingServiceProtocol {
  struct InfoCall {
    let message: String
    let event: String
    let userInfo: [String: Any]?
  }

  private(set) var logInfoCalls: [InfoCall] = []

  func logInfo(message: String, event: String, userInfo: [String: Any]?) async {
    logInfoCalls.append(InfoCall(message: message, event: event, userInfo: userInfo))
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
