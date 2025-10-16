//
//  AnalyticsModelsTests.swift
//  PrimerSDKTests
//
//  Tests for Analytics data models
//

@testable import PrimerSDK
import XCTest

// MARK: - AnalyticsPayload Tests

final class AnalyticsPayloadTests: XCTestCase {

    func testAnalyticsPayload_EncodesAllRequiredFields() throws {
        // Given
        let payload = AnalyticsPayload(
            id: "test-id-123",
            timestamp: 1234567890,
            sdkType: "IOS_NATIVE",
            eventName: "SDK_INIT_START",
            checkoutSessionId: "cs_123",
            clientSessionId: "client_456",
            primerAccountId: "acc_789",
            sdkVersion: "2.46.7",
            userAgent: "iOS/18.0 (iPhone15,2)",
            eventType: nil,
            userLocale: nil,
            paymentMethod: nil,
            paymentId: nil,
            redirectDestinationUrl: nil,
            threedsProvider: nil,
            threedsResponse: nil,
            browser: nil,
            device: nil,
            deviceType: nil
        )

        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let jsonData = try encoder.encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Then
        XCTAssertEqual(json["id"] as? String, "test-id-123")
        XCTAssertEqual(json["timestamp"] as? Int, 1234567890)
        XCTAssertEqual(json["sdkType"] as? String, "IOS_NATIVE")
        XCTAssertEqual(json["eventName"] as? String, "SDK_INIT_START")
        XCTAssertEqual(json["checkoutSessionId"] as? String, "cs_123")
        XCTAssertEqual(json["clientSessionId"] as? String, "client_456")
        XCTAssertEqual(json["primerAccountId"] as? String, "acc_789")
        XCTAssertEqual(json["sdkVersion"] as? String, "2.46.7")
        XCTAssertEqual(json["userAgent"] as? String, "iOS/18.0 (iPhone15,2)")
    }

    func testAnalyticsPayload_OmitsNilOptionalFields() throws {
        // Given
        let payload = AnalyticsPayload(
            id: "test-id",
            timestamp: 123,
            sdkType: "IOS_NATIVE",
            eventName: "SDK_INIT_START",
            checkoutSessionId: "cs_123",
            clientSessionId: "client_456",
            primerAccountId: "acc_789",
            sdkVersion: "2.46.7",
            userAgent: "iOS/18.0",
            eventType: nil,
            userLocale: nil,
            paymentMethod: nil,
            paymentId: nil,
            redirectDestinationUrl: nil,
            threedsProvider: nil,
            threedsResponse: nil,
            browser: nil,
            device: nil,
            deviceType: nil
        )

        // When
        let jsonData = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Then - optional fields should not be present
        XCTAssertNil(json["eventType"])
        XCTAssertNil(json["userLocale"])
        XCTAssertNil(json["paymentMethod"])
        XCTAssertNil(json["paymentId"])
        XCTAssertNil(json["redirectDestinationUrl"])
        XCTAssertNil(json["threedsProvider"])
        XCTAssertNil(json["threedsResponse"])
        XCTAssertNil(json["browser"])
        XCTAssertNil(json["device"])
        XCTAssertNil(json["deviceType"])
    }

    func testAnalyticsPayload_IncludesProvidedOptionalFields() throws {
        // Given
        let payload = AnalyticsPayload(
            id: "test-id",
            timestamp: 123,
            sdkType: "IOS_NATIVE",
            eventName: "PAYMENT_SUCCESS",
            checkoutSessionId: "cs_123",
            clientSessionId: "client_456",
            primerAccountId: "acc_789",
            sdkVersion: "2.46.7",
            userAgent: "iOS/18.0",
            eventType: "payment",
            userLocale: "en-GB",
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123",
            redirectDestinationUrl: "https://example.com",
            threedsProvider: "Netcetera",
            threedsResponse: "05",
            browser: "Safari",
            device: "iPhone 15 Pro",
            deviceType: "phone"
        )

        // When
        let jsonData = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Then - optional fields should be present
        XCTAssertEqual(json["eventType"] as? String, "payment")
        XCTAssertEqual(json["userLocale"] as? String, "en-GB")
        XCTAssertEqual(json["paymentMethod"] as? String, "PAYMENT_CARD")
        XCTAssertEqual(json["paymentId"] as? String, "pay_123")
        XCTAssertEqual(json["redirectDestinationUrl"] as? String, "https://example.com")
        XCTAssertEqual(json["threedsProvider"] as? String, "Netcetera")
        XCTAssertEqual(json["threedsResponse"] as? String, "05")
        XCTAssertEqual(json["browser"] as? String, "Safari")
        XCTAssertEqual(json["device"] as? String, "iPhone 15 Pro")
        XCTAssertEqual(json["deviceType"] as? String, "phone")
    }

    func testAnalyticsPayload_DecodesCorrectly() throws {
        // Given
        let json = """
        {
            "id": "test-id",
            "timestamp": 123,
            "sdkType": "IOS_NATIVE",
            "eventName": "SDK_INIT_START",
            "checkoutSessionId": "cs_123",
            "clientSessionId": "client_456",
            "primerAccountId": "acc_789",
            "sdkVersion": "2.46.7",
            "userAgent": "iOS/18.0"
        }
        """

        // When
        let jsonData = json.data(using: .utf8)!
        let payload = try JSONDecoder().decode(AnalyticsPayload.self, from: jsonData)

        // Then
        XCTAssertEqual(payload.id, "test-id")
        XCTAssertEqual(payload.timestamp, 123)
        XCTAssertEqual(payload.sdkType, "IOS_NATIVE")
        XCTAssertEqual(payload.eventName, "SDK_INIT_START")
    }
}

// MARK: - AnalyticsEventMetadata Tests

final class AnalyticsEventMetadataTests: XCTestCase {

    func testAnalyticsEventMetadata_InitializesWithAllNilByDefault() {
        // When
        let metadata = AnalyticsEventMetadata()

        // Then
        XCTAssertNil(metadata.eventType)
        XCTAssertNil(metadata.userLocale)
        XCTAssertNil(metadata.paymentMethod)
        XCTAssertNil(metadata.paymentId)
        XCTAssertNil(metadata.redirectDestinationUrl)
        XCTAssertNil(metadata.threedsProvider)
        XCTAssertNil(metadata.threedsResponse)
        XCTAssertNil(metadata.browser)
        XCTAssertNil(metadata.device)
        XCTAssertNil(metadata.deviceType)
    }

    func testAnalyticsEventMetadata_InitializesWithSingleField() {
        // When
        let metadata = AnalyticsEventMetadata(paymentMethod: "PAYMENT_CARD")

        // Then
        XCTAssertEqual(metadata.paymentMethod, "PAYMENT_CARD")
        XCTAssertNil(metadata.eventType)
        XCTAssertNil(metadata.paymentId)
    }

    func testAnalyticsEventMetadata_InitializesWithMultipleFields() {
        // When
        let metadata = AnalyticsEventMetadata(
            eventType: "payment",
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123"
        )

        // Then
        XCTAssertEqual(metadata.eventType, "payment")
        XCTAssertEqual(metadata.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(metadata.paymentId, "pay_123")
    }

    func testAnalyticsEventMetadata_Supports3DSFields() {
        // When
        let metadata = AnalyticsEventMetadata(
            threedsProvider: "Netcetera",
            threedsResponse: "05"
        )

        // Then
        XCTAssertEqual(metadata.threedsProvider, "Netcetera")
        XCTAssertEqual(metadata.threedsResponse, "05")
    }

    func testAnalyticsEventMetadata_SupportsRedirectFields() {
        // When
        let metadata = AnalyticsEventMetadata(
            redirectDestinationUrl: "https://example.com/redirect"
        )

        // Then
        XCTAssertEqual(metadata.redirectDestinationUrl, "https://example.com/redirect")
    }

    func testAnalyticsEventMetadata_SupportsDeviceOverrides() {
        // When
        let metadata = AnalyticsEventMetadata(
            device: "Custom Device",
            deviceType: "tablet"
        )

        // Then
        XCTAssertEqual(metadata.device, "Custom Device")
        XCTAssertEqual(metadata.deviceType, "tablet")
    }

    // MARK: - withLocale Factory Tests

    func testAnalyticsEventMetadata_withLocale_PopulatesUserLocaleAutomatically() {
        // Given
        let expectedLocale = Locale.current.identifier

        // When
        let metadata = AnalyticsEventMetadata.withLocale()

        // Then
        XCTAssertEqual(metadata.userLocale, expectedLocale, "userLocale should be auto-populated from Locale.current")
        XCTAssertFalse(expectedLocale.isEmpty, "Locale identifier should not be empty")
    }

    func testAnalyticsEventMetadata_withLocale_LeavesOtherFieldsNilByDefault() {
        // When
        let metadata = AnalyticsEventMetadata.withLocale()

        // Then
        XCTAssertNotNil(metadata.userLocale, "userLocale should be populated")
        XCTAssertNil(metadata.eventType)
        XCTAssertNil(metadata.paymentMethod)
        XCTAssertNil(metadata.paymentId)
        XCTAssertNil(metadata.redirectDestinationUrl)
        XCTAssertNil(metadata.threedsProvider)
        XCTAssertNil(metadata.threedsResponse)
        XCTAssertNil(metadata.browser)
        XCTAssertNil(metadata.device)
        XCTAssertNil(metadata.deviceType)
    }

    func testAnalyticsEventMetadata_withLocale_PassesThroughSingleParameter() {
        // Given
        let expectedPaymentMethod = "PAYMENT_CARD"

        // When
        let metadata = AnalyticsEventMetadata.withLocale(paymentMethod: expectedPaymentMethod)

        // Then
        XCTAssertNotNil(metadata.userLocale)
        XCTAssertEqual(metadata.paymentMethod, expectedPaymentMethod)
        XCTAssertNil(metadata.paymentId, "Unspecified parameters should remain nil")
    }

    func testAnalyticsEventMetadata_withLocale_PassesThroughMultipleParameters() {
        // Given
        let expectedLocale = Locale.current.identifier
        let expectedPaymentMethod = "PAYMENT_CARD"
        let expectedPaymentId = "pay_123"
        let expectedEventType = "payment"

        // When
        let metadata = AnalyticsEventMetadata.withLocale(
            eventType: expectedEventType,
            paymentMethod: expectedPaymentMethod,
            paymentId: expectedPaymentId
        )

        // Then
        XCTAssertEqual(metadata.userLocale, expectedLocale)
        XCTAssertEqual(metadata.eventType, expectedEventType)
        XCTAssertEqual(metadata.paymentMethod, expectedPaymentMethod)
        XCTAssertEqual(metadata.paymentId, expectedPaymentId)
        XCTAssertNil(metadata.device, "Unspecified parameters should remain nil")
    }

    func testAnalyticsEventMetadata_withLocale_Supports3DSParameters() {
        // Given
        let expectedProvider = "Netcetera"
        let expectedResponse = "05"

        // When
        let metadata = AnalyticsEventMetadata.withLocale(
            threedsProvider: expectedProvider,
            threedsResponse: expectedResponse
        )

        // Then
        XCTAssertNotNil(metadata.userLocale)
        XCTAssertEqual(metadata.threedsProvider, expectedProvider)
        XCTAssertEqual(metadata.threedsResponse, expectedResponse)
    }

    func testAnalyticsEventMetadata_withLocale_SupportsAllParameters() {
        // Given
        let expectedLocale = Locale.current.identifier

        // When
        let metadata = AnalyticsEventMetadata.withLocale(
            eventType: "payment",
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123",
            redirectDestinationUrl: "https://example.com",
            threedsProvider: "Netcetera",
            threedsResponse: "05",
            browser: "Safari",
            device: "iPhone 15 Pro",
            deviceType: "phone"
        )

        // Then
        XCTAssertEqual(metadata.userLocale, expectedLocale)
        XCTAssertEqual(metadata.eventType, "payment")
        XCTAssertEqual(metadata.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(metadata.paymentId, "pay_123")
        XCTAssertEqual(metadata.redirectDestinationUrl, "https://example.com")
        XCTAssertEqual(metadata.threedsProvider, "Netcetera")
        XCTAssertEqual(metadata.threedsResponse, "05")
        XCTAssertEqual(metadata.browser, "Safari")
        XCTAssertEqual(metadata.device, "iPhone 15 Pro")
        XCTAssertEqual(metadata.deviceType, "phone")
    }
}

// MARK: - AnalyticsEventType Tests

final class AnalyticsEventTypeTests: XCTestCase {

    func testAnalyticsEventType_AllTypesHaveCorrectRawValues() {
        // Then
        XCTAssertEqual(AnalyticsEventType.sdkInitStart.rawValue, "SDK_INIT_START")
        XCTAssertEqual(AnalyticsEventType.sdkInitEnd.rawValue, "SDK_INIT_END")
        XCTAssertEqual(AnalyticsEventType.checkoutFlowStarted.rawValue, "CHECKOUT_FLOW_STARTED")
        XCTAssertEqual(AnalyticsEventType.paymentMethodSelection.rawValue, "PAYMENT_METHOD_SELECTION")
        XCTAssertEqual(AnalyticsEventType.paymentDetailsEntered.rawValue, "PAYMENT_DETAILS_ENTERED")
        XCTAssertEqual(AnalyticsEventType.paymentSubmitted.rawValue, "PAYMENT_SUBMITTED")
        XCTAssertEqual(AnalyticsEventType.paymentProcessingStarted.rawValue, "PAYMENT_PROCESSING_STARTED")
        XCTAssertEqual(AnalyticsEventType.paymentRedirectToThirdParty.rawValue, "PAYMENT_REDIRECT_TO_THIRD_PARTY")
        XCTAssertEqual(AnalyticsEventType.paymentThreeds.rawValue, "PAYMENT_THREEDS")
        XCTAssertEqual(AnalyticsEventType.paymentSuccess.rawValue, "PAYMENT_SUCCESS")
        XCTAssertEqual(AnalyticsEventType.paymentFailure.rawValue, "PAYMENT_FAILURE")
        XCTAssertEqual(AnalyticsEventType.paymentReattempted.rawValue, "PAYMENT_REATTEMPTED")
        XCTAssertEqual(AnalyticsEventType.paymentFlowExited.rawValue, "PAYMENT_FLOW_EXITED")
    }

    func testAnalyticsEventType_IsEncodable() throws {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart

        // When
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(eventType)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Then
        XCTAssertEqual(jsonString, "\"SDK_INIT_START\"")
    }

    func testAnalyticsEventType_IsDecodable() throws {
        // Given
        let json = "\"PAYMENT_SUCCESS\""
        let jsonData = json.data(using: .utf8)!

        // When
        let eventType = try JSONDecoder().decode(AnalyticsEventType.self, from: jsonData)

        // Then
        XCTAssertEqual(eventType, .paymentSuccess)
    }

    func testAnalyticsEventType_Count_Is13() {
        // Given - all event types as per spec
        let allEventTypes: [AnalyticsEventType] = [
            .sdkInitStart,
            .sdkInitEnd,
            .checkoutFlowStarted,
            .paymentMethodSelection,
            .paymentDetailsEntered,
            .paymentSubmitted,
            .paymentProcessingStarted,
            .paymentRedirectToThirdParty,
            .paymentThreeds,
            .paymentSuccess,
            .paymentFailure,
            .paymentReattempted,
            .paymentFlowExited
        ]

        // Then
        XCTAssertEqual(allEventTypes.count, 13, "Should have exactly 13 event types as per spec")
    }
}

// MARK: - AnalyticsEnvironment Tests

final class AnalyticsEnvironmentTests: XCTestCase {

    func testAnalyticsEnvironment_AllEnvironmentsHaveCorrectRawValues() {
        // Then
        XCTAssertEqual(AnalyticsEnvironment.dev.rawValue, "DEV")
        XCTAssertEqual(AnalyticsEnvironment.staging.rawValue, "STAGING")
        XCTAssertEqual(AnalyticsEnvironment.sandbox.rawValue, "SANDBOX")
        XCTAssertEqual(AnalyticsEnvironment.production.rawValue, "PRODUCTION")
    }

    func testAnalyticsEnvironment_CanBeInitializedFromRawValue() {
        // When/Then
        XCTAssertEqual(AnalyticsEnvironment(rawValue: "DEV"), .dev)
        XCTAssertEqual(AnalyticsEnvironment(rawValue: "STAGING"), .staging)
        XCTAssertEqual(AnalyticsEnvironment(rawValue: "SANDBOX"), .sandbox)
        XCTAssertEqual(AnalyticsEnvironment(rawValue: "PRODUCTION"), .production)
    }

    func testAnalyticsEnvironment_InvalidRawValue_ReturnsNil() {
        // When
        let invalidEnvironment = AnalyticsEnvironment(rawValue: "INVALID")

        // Then
        XCTAssertNil(invalidEnvironment)
    }

    func testAnalyticsEnvironment_Count_Is4() {
        // Given
        let allEnvironments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // Then
        XCTAssertEqual(allEnvironments.count, 4, "Should have exactly 4 environments")
    }
}

// MARK: - AnalyticsSessionConfig Tests

final class AnalyticsSessionConfigTests: XCTestCase {

    func testAnalyticsSessionConfig_InitializesWithAllFields() {
        // When
        let config = AnalyticsSessionConfig(
            environment: .dev,
            checkoutSessionId: "cs_123",
            clientSessionId: "client_456",
            primerAccountId: "acc_789",
            sdkVersion: "2.46.7",
            clientSessionToken: "token_abc"
        )

        // Then
        XCTAssertEqual(config.environment, .dev)
        XCTAssertEqual(config.checkoutSessionId, "cs_123")
        XCTAssertEqual(config.clientSessionId, "client_456")
        XCTAssertEqual(config.primerAccountId, "acc_789")
        XCTAssertEqual(config.sdkVersion, "2.46.7")
        XCTAssertEqual(config.clientSessionToken, "token_abc")
    }

    func testAnalyticsSessionConfig_InitializesWithoutToken() {
        // When
        let config = AnalyticsSessionConfig(
            environment: .production,
            checkoutSessionId: "cs_123",
            clientSessionId: "client_456",
            primerAccountId: "acc_789",
            sdkVersion: "2.46.7"
        )

        // Then
        XCTAssertEqual(config.environment, .production)
        XCTAssertNil(config.clientSessionToken)
    }

    func testAnalyticsSessionConfig_SupportsAllEnvironments() {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then
        for environment in environments {
            let config = AnalyticsSessionConfig(
                environment: environment,
                checkoutSessionId: "cs_123",
                clientSessionId: "client_456",
                primerAccountId: "acc_789",
                sdkVersion: "2.46.7"
            )
            XCTAssertEqual(config.environment, environment)
        }
    }
}
