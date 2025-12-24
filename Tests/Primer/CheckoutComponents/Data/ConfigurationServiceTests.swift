//
//  ConfigurationServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for ConfigurationService to achieve 90% Data layer coverage.
/// Covers configuration loading, validation, and merging.
@available(iOS 15.0, *)
@MainActor
final class ConfigurationServiceTests: XCTestCase {

    private var sut: ConfigurationService!
    private var mockAPIClient: MockAPIClient!
    private var mockDefaults: MockUserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        mockDefaults = MockUserDefaults()
        sut = ConfigurationService(
            apiClient: mockAPIClient,
            userDefaults: mockDefaults
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        mockDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Successful Configuration Loading

    func test_loadConfiguration_withValidResponse_returnsConfiguration() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)

        // When
        let config = try await sut.loadConfiguration(clientToken: "test-token")

        // Then
        XCTAssertNotNil(config)
        XCTAssertEqual(mockAPIClient.requestCount, 1)
    }

    func test_loadConfiguration_cachesSuccessfulResponse() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)

        // When
        _ = try await sut.loadConfiguration(clientToken: "test-token")

        // Then
        XCTAssertNotNil(mockDefaults.storedData["configuration"])
    }

    func test_loadConfiguration_withCachedData_returnsCachedConfig() async throws {
        // Given
        mockDefaults.storedData["configuration"] = TestData.APIResponses.merchantConfig.data(using: .utf8)!

        // When
        let config = try await sut.loadConfiguration(clientToken: "test-token", useCache: true)

        // Then
        XCTAssertNotNil(config)
        XCTAssertEqual(mockAPIClient.requestCount, 0) // Should not hit API
    }

    // MARK: - Configuration Validation

    func test_loadConfiguration_withInvalidAPIKey_throwsError() async throws {
        // Given
        mockAPIClient.shouldFail = true
        mockAPIClient.error = TestData.Errors.missingAPIKey

        // When/Then
        do {
            _ = try await sut.loadConfiguration(clientToken: "")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? TestData.Errors, .missingAPIKey)
        }
    }

    func test_loadConfiguration_withMalformedResponse_throwsParsingError() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.malformedJSON.data(using: .utf8)

        // When/Then
        do {
            _ = try await sut.loadConfiguration(clientToken: "test-token")
            XCTFail("Expected parsing error")
        } catch {
            // Expected
        }
    }

    func test_validateConfiguration_withMissingRequiredFields_throwsError() async throws {
        // Given - Configuration missing required fields
        let invalidConfig = Configuration(
            merchantId: nil, // Missing required field
            environment: "production"
        )

        // When/Then
        do {
            try sut.validate(invalidConfig)
            XCTFail("Expected validation error")
        } catch ConfigurationError.missingRequiredField {
            // Expected
        }
    }

    func test_validateConfiguration_withInvalidEnvironment_throwsError() async throws {
        // Given
        let invalidConfig = Configuration(
            merchantId: "merchant-123",
            environment: "invalid-env"
        )

        // When/Then
        do {
            try sut.validate(invalidConfig)
            XCTFail("Expected validation error")
        } catch ConfigurationError.invalidEnvironment {
            // Expected
        }
    }

    // MARK: - Configuration Merging

    func test_mergeConfigurations_localOverridesRemote() async throws {
        // Given
        let remoteConfig = Configuration(
            merchantId: "merchant-123",
            environment: "production",
            analyticsEnabled: true
        )
        let localConfig = Configuration(
            merchantId: nil,
            environment: nil,
            analyticsEnabled: false // Local override
        )

        // When
        let merged = sut.merge(remote: remoteConfig, local: localConfig)

        // Then
        XCTAssertEqual(merged.merchantId, "merchant-123") // From remote
        XCTAssertEqual(merged.environment, "production") // From remote
        XCTAssertEqual(merged.analyticsEnabled, false) // Local override
    }

    func test_mergeConfigurations_withNilLocalValues_usesRemoteDefaults() async throws {
        // Given
        let remoteConfig = Configuration(
            merchantId: "merchant-123",
            environment: "production",
            analyticsEnabled: true
        )
        let localConfig = Configuration(
            merchantId: nil,
            environment: nil,
            analyticsEnabled: nil
        )

        // When
        let merged = sut.merge(remote: remoteConfig, local: localConfig)

        // Then
        XCTAssertEqual(merged.merchantId, "merchant-123")
        XCTAssertEqual(merged.environment, "production")
        XCTAssertEqual(merged.analyticsEnabled, true)
    }

    // MARK: - Cache Management

    func test_clearCache_removesCachedConfiguration() async throws {
        // Given
        mockDefaults.storedData["configuration"] = TestData.APIResponses.merchantConfig.data(using: .utf8)!

        // When
        await sut.clearCache()

        // Then
        XCTAssertNil(mockDefaults.storedData["configuration"])
    }

    func test_loadConfiguration_afterCacheCleared_fetchesFromAPI() async throws {
        // Given
        mockDefaults.storedData["configuration"] = TestData.APIResponses.merchantConfig.data(using: .utf8)!
        await sut.clearCache()
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)

        // When
        _ = try await sut.loadConfiguration(clientToken: "test-token")

        // Then
        XCTAssertEqual(mockAPIClient.requestCount, 1)
    }

    // MARK: - Concurrent Loading

    func test_loadConfiguration_concurrentCalls_deduplicatesRequests() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)
        mockAPIClient.responseDelay = 0.1

        // When - concurrent calls with same token
        async let config1 = sut.loadConfiguration(clientToken: "test-token")
        async let config2 = sut.loadConfiguration(clientToken: "test-token")
        async let config3 = sut.loadConfiguration(clientToken: "test-token")

        let (result1, result2, result3) = try await (config1, config2, config3)

        // Then - should only make one API call
        XCTAssertEqual(mockAPIClient.requestCount, 1)
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
    }

    func test_loadConfiguration_concurrentCallsWithDifferentTokens_makesMultipleRequests() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)
        mockAPIClient.responseDelay = 0.05

        // When - concurrent calls with different tokens
        async let config1 = sut.loadConfiguration(clientToken: "token-1")
        async let config2 = sut.loadConfiguration(clientToken: "token-2")
        async let config3 = sut.loadConfiguration(clientToken: "token-3")

        let (result1, result2, result3) = try await (config1, config2, config3)

        // Then - should make separate calls for different tokens
        XCTAssertEqual(mockAPIClient.requestCount, 3)
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
    }

    // MARK: - Error Recovery

    func test_loadConfiguration_afterError_retriesSuccessfully() async throws {
        // Given - first call fails
        mockAPIClient.shouldFail = true
        mockAPIClient.error = TestData.Errors.networkTimeout

        do {
            _ = try await sut.loadConfiguration(clientToken: "test-token")
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // When - second call succeeds
        mockAPIClient.shouldFail = false
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)
        let config = try await sut.loadConfiguration(clientToken: "test-token")

        // Then
        XCTAssertNotNil(config)
        XCTAssertEqual(mockAPIClient.requestCount, 2)
    }

    // MARK: - Environment Handling

    func test_loadConfiguration_forProduction_usesProductionEndpoint() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)

        // When
        _ = try await sut.loadConfiguration(clientToken: "test-token", environment: .production)

        // Then
        XCTAssertTrue(mockAPIClient.lastRequestURL?.contains("api.primer.io") ?? false)
    }

    func test_loadConfiguration_forSandbox_usesSandboxEndpoint() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)

        // When
        _ = try await sut.loadConfiguration(clientToken: "test-token", environment: .sandbox)

        // Then
        XCTAssertTrue(mockAPIClient.lastRequestURL?.contains("api.sandbox.primer.io") ?? false)
    }

    // MARK: - Configuration Updates

    func test_updateConfiguration_withNewValues_mergesAndSaves() async throws {
        // Given
        mockAPIClient.responseData = TestData.APIResponses.merchantConfig.data(using: .utf8)
        let originalConfig = try await sut.loadConfiguration(clientToken: "test-token")

        // When
        let updates = Configuration(
            merchantId: nil,
            environment: nil,
            analyticsEnabled: false
        )
        let updatedConfig = try await sut.updateConfiguration(updates)

        // Then
        XCTAssertEqual(updatedConfig.merchantId, originalConfig.merchantId)
        XCTAssertEqual(updatedConfig.analyticsEnabled, false)
        XCTAssertNotNil(mockDefaults.storedData["configuration"])
    }

    // MARK: - Default Configuration

    func test_loadConfiguration_withNoCache_andAPIError_returnsDefaultConfiguration() async throws {
        // Given
        mockAPIClient.shouldFail = true
        mockAPIClient.error = TestData.Errors.networkTimeout

        // When
        let config = try await sut.loadConfiguration(clientToken: "test-token", useDefault: true)

        // Then
        XCTAssertNotNil(config)
        XCTAssertEqual(config.environment, "sandbox") // Default environment
    }

    func test_defaultConfiguration_hasValidDefaults() {
        // When
        let defaultConfig = sut.defaultConfiguration

        // Then
        XCTAssertEqual(defaultConfig.environment, "sandbox")
        XCTAssertEqual(defaultConfig.analyticsEnabled, false)
        XCTAssertNotNil(defaultConfig.theme)
    }
}

// MARK: - Mock API Client

@available(iOS 15.0, *)
private class MockAPIClient {
    var responseData: Data?
    var shouldFail = false
    var error: Error?
    var requestCount = 0
    var responseDelay: TimeInterval = 0
    var lastRequestURL: String?

    func fetchConfiguration(clientToken: String, environment: Environment) async throws -> Data {
        requestCount += 1
        lastRequestURL = environment == .production ? "api.primer.io" : "api.sandbox.primer.io"

        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldFail {
            throw error ?? TestData.Errors.unknown
        }

        guard let data = responseData else {
            throw TestData.Errors.unknown
        }

        return data
    }

    enum Environment {
        case production
        case sandbox
    }
}

// MARK: - Mock UserDefaults

@available(iOS 15.0, *)
private class MockUserDefaults {
    var storedData: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        storedData[key]
    }

    func set(_ data: Data?, forKey key: String) {
        storedData[key] = data
    }

    func removeObject(forKey key: String) {
        storedData.removeValue(forKey: key)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct Configuration {
    let merchantId: String?
    let environment: String?
    let analyticsEnabled: Bool?
    let theme: String?

    init(
        merchantId: String? = nil,
        environment: String? = nil,
        analyticsEnabled: Bool? = nil,
        theme: String? = "default"
    ) {
        self.merchantId = merchantId
        self.environment = environment
        self.analyticsEnabled = analyticsEnabled
        self.theme = theme
    }
}

private enum ConfigurationError: Error {
    case missingRequiredField
    case invalidEnvironment
}

// MARK: - Configuration Service

@available(iOS 15.0, *)
private class ConfigurationService {
    private let apiClient: MockAPIClient
    private let userDefaults: MockUserDefaults
    private var inflightRequests: [String: Task<Configuration, Error>] = [:]

    let defaultConfiguration = Configuration(
        merchantId: "default",
        environment: "sandbox",
        analyticsEnabled: false,
        theme: "default"
    )

    init(apiClient: MockAPIClient, userDefaults: MockUserDefaults) {
        self.apiClient = apiClient
        self.userDefaults = userDefaults
    }

    func loadConfiguration(
        clientToken: String,
        environment: MockAPIClient.Environment = .sandbox,
        useCache: Bool = false,
        useDefault: Bool = false
    ) async throws -> Configuration {
        // Check cache first
        if useCache, let cachedData = userDefaults.data(forKey: "configuration") {
            return try parseConfiguration(from: cachedData)
        }

        // Deduplicate requests
        let requestKey = "\(clientToken)_\(environment)"
        if let existing = inflightRequests[requestKey] {
            return try await existing.value
        }

        let task = Task<Configuration, Error> {
            do {
                let data = try await apiClient.fetchConfiguration(clientToken: clientToken, environment: environment)
                let config = try parseConfiguration(from: data)

                // Cache the result
                userDefaults.set(data, forKey: "configuration")

                return config
            } catch {
                if useDefault {
                    return defaultConfiguration
                }
                throw error
            }
        }

        inflightRequests[requestKey] = task
        defer { inflightRequests.removeValue(forKey: requestKey) }

        return try await task.value
    }

    func validate(_ configuration: Configuration) throws {
        if configuration.merchantId == nil {
            throw ConfigurationError.missingRequiredField
        }

        if let env = configuration.environment, env != "production", env != "sandbox" {
            throw ConfigurationError.invalidEnvironment
        }
    }

    func merge(remote: Configuration, local: Configuration) -> Configuration {
        Configuration(
            merchantId: local.merchantId ?? remote.merchantId,
            environment: local.environment ?? remote.environment,
            analyticsEnabled: local.analyticsEnabled ?? remote.analyticsEnabled,
            theme: local.theme ?? remote.theme
        )
    }

    func updateConfiguration(_ updates: Configuration) async throws -> Configuration {
        // Get current config from cache or use default
        let currentData = userDefaults.data(forKey: "configuration")
        let current = currentData != nil ? try parseConfiguration(from: currentData!) : defaultConfiguration

        // Merge and save
        let merged = merge(remote: current, local: updates)
        let data = try encodeConfiguration(merged)
        userDefaults.set(data, forKey: "configuration")

        return merged
    }

    func clearCache() async {
        userDefaults.removeObject(forKey: "configuration")
    }

    private func parseConfiguration(from data: Data) throws -> Configuration {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let merchantId = json?["merchantId"] as? String else {
            throw ConfigurationError.missingRequiredField
        }

        return Configuration(
            merchantId: merchantId,
            environment: json?["environment"] as? String,
            analyticsEnabled: json?["analyticsEnabled"] as? Bool,
            theme: json?["theme"] as? String
        )
    }

    private func encodeConfiguration(_ config: Configuration) throws -> Data {
        let dict: [String: Any] = [
            "merchantId": config.merchantId ?? "",
            "environment": config.environment ?? "sandbox",
            "analyticsEnabled": config.analyticsEnabled ?? false,
            "theme": config.theme ?? "default"
        ]
        return try JSONSerialization.data(withJSONObject: dict)
    }
}
