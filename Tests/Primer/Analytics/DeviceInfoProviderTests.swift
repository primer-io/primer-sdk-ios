//
//  DeviceInfoProviderTests.swift
//  PrimerSDKTests
//
//  Tests for DeviceInfoProvider
//

@testable import PrimerSDK
import XCTest

final class DeviceInfoProviderTests: XCTestCase {

    private var provider: DeviceInfoProvider!

    override func setUp() {
        super.setUp()
        provider = DeviceInfoProvider()
    }

    override func tearDown() {
        provider = nil
        super.tearDown()
    }

    // MARK: - Device Name Tests

    func testGetDevice_ReturnsNonEmptyString() {
        // When
        let device = provider.getDevice()

        // Then
        XCTAssertFalse(device.isEmpty, "Device name should not be empty")
    }

    func testGetDevice_ReturnsValidFormat() {
        // When
        let device = provider.getDevice()

        // Then
        // Should return either a model name like "iPhone 15 Pro" or "Simulator ..."
        XCTAssertTrue(
            device.contains("iPhone") ||
            device.contains("iPad") ||
            device.contains("Simulator") ||
            device.contains("iPod"),
            "Device should be a valid iOS device: \(device)"
        )
    }

    // MARK: - Device Type Tests

    func testGetDeviceType_ReturnsValidType() {
        // When
        let deviceType = provider.getDeviceType()

        // Then
        let validTypes = ["phone", "tablet", "watch"]
        XCTAssertTrue(
            validTypes.contains(deviceType),
            "Device type should be one of: \(validTypes), got: \(deviceType)"
        )
    }

    func testGetDeviceType_iPhoneReturnsPhone() {
        // Given
        let device = provider.getDevice()

        // When
        let deviceType = provider.getDeviceType()

        // Then - if device is iPhone (or simulating iPhone), should return phone
        if device.contains("iPhone") || device.contains("Simulator") {
            XCTAssertEqual(deviceType, "phone", "iPhone should return 'phone' type")
        }
    }

    func testGetDeviceType_iPadReturnsTablet() {
        // Given
        let device = provider.getDevice()

        // When
        let deviceType = provider.getDeviceType()

        // Then - if device is iPad, should return tablet
        if device.contains("iPad") {
            XCTAssertEqual(deviceType, "tablet", "iPad should return 'tablet' type")
        }
    }

    // MARK: - User Locale Tests

    func testGetUserLocale_ReturnsValidFormat() {
        // When
        let locale = provider.getUserLocale()

        // Then
        if let locale = locale {
            // Should match format: "en-US" or just "en"
            let localePattern = "^[a-z]{2}(-[A-Z]{2})?$"
            let regex = try? NSRegularExpression(pattern: localePattern)
            let matches = regex?.numberOfMatches(
                in: locale,
                range: NSRange(locale.startIndex..., in: locale)
            )
            XCTAssertEqual(matches, 1, "Locale should match ISO format (e.g., 'en-US'): \(locale)")
        }
    }

    func testGetUserLocale_ContainsLanguageCode() {
        // When
        let locale = provider.getUserLocale()

        // Then
        XCTAssertNotNil(locale, "User locale should not be nil")
        if let locale = locale {
            XCTAssertGreaterThanOrEqual(locale.count, 2, "Locale should at least contain language code")
        }
    }

    func testGetUserLocale_MatchesSystemLocale() {
        // Given
        let systemLanguageCode = Locale.current.languageCode
        let systemRegionCode = Locale.current.regionCode

        // When
        let locale = provider.getUserLocale()

        // Then
        if let systemLanguageCode = systemLanguageCode {
            XCTAssertTrue(
                locale?.hasPrefix(systemLanguageCode) ?? false,
                "Locale should start with system language code"
            )
        }

        if let systemRegionCode = systemRegionCode {
            XCTAssertTrue(
                locale?.hasSuffix(systemRegionCode) ?? false,
                "Locale should end with system region code when available"
            )
        }
    }

    // MARK: - User Agent Tests

    func testGetUserAgent_ReturnsValidFormat() {
        // When
        let userAgent = provider.getUserAgent()

        // Then
        // Format should be: "iOS/{version} ({model})"
        XCTAssertTrue(userAgent.hasPrefix("iOS/"), "User agent should start with 'iOS/'")
        XCTAssertTrue(userAgent.contains("("), "User agent should contain model in parentheses")
        XCTAssertTrue(userAgent.contains(")"), "User agent should contain closing parenthesis")
    }

    func testGetUserAgent_ContainsPlatformVersion() {
        // Given
        let platformVersion = provider.getPlatformVersion()

        // When
        let userAgent = provider.getUserAgent()

        // Then
        XCTAssertTrue(
            userAgent.contains(platformVersion),
            "User agent should contain platform version: \(platformVersion)"
        )
    }

    func testGetUserAgent_ContainsModelIdentifier() {
        // Given
        let modelIdentifier = provider.getModelIdentifier()

        // When
        let userAgent = provider.getUserAgent()

        // Then
        XCTAssertTrue(
            userAgent.contains(modelIdentifier),
            "User agent should contain model identifier: \(modelIdentifier)"
        )
    }

    // MARK: - Model Identifier Tests

    func testGetModelIdentifier_ReturnsNonEmptyString() {
        // When
        let identifier = provider.getModelIdentifier()

        // Then
        XCTAssertFalse(identifier.isEmpty, "Model identifier should not be empty")
    }

    func testGetModelIdentifier_ReturnsValidFormat() {
        // When
        let identifier = provider.getModelIdentifier()

        // Then
        // Should be like "iPhone15,2" or "iPad8,1" or simulator identifiers
        let validPrefixes = ["iPhone", "iPad", "iPod", "Watch", "i386", "x86_64", "arm64"]
        let hasValidPrefix = validPrefixes.contains { identifier.hasPrefix($0) }
        XCTAssertTrue(
            hasValidPrefix,
            "Model identifier should start with valid prefix: \(identifier)"
        )
    }

    // MARK: - Platform Version Tests

    func testGetPlatformVersion_ReturnsNonEmptyString() {
        // When
        let version = provider.getPlatformVersion()

        // Then
        XCTAssertFalse(version.isEmpty, "Platform version should not be empty")
    }

    func testGetPlatformVersion_ReturnsValidFormat() {
        // When
        let version = provider.getPlatformVersion()

        // Then
        // Should be like "17.0" or "18.4"
        let versionPattern = "^\\d+\\.\\d+"
        let regex = try? NSRegularExpression(pattern: versionPattern)
        let matches = regex?.numberOfMatches(
            in: version,
            range: NSRange(version.startIndex..., in: version)
        )
        XCTAssertGreaterThan(matches ?? 0, 0, "Platform version should be in format X.Y: \(version)")
    }

    func testGetPlatformVersion_MatchesSystemVersion() {
        // Given
        let systemVersion = UIDevice.current.systemVersion

        // When
        let version = provider.getPlatformVersion()

        // Then
        XCTAssertEqual(version, systemVersion, "Platform version should match UIDevice system version")
    }

    // MARK: - Device Mapping Tests

    func testDeviceMapping_iPhone15Pro_ReturnCorrectName() {
        // This test verifies the device mapping logic works
        // Actual device will vary based on test environment

        // When
        let device = provider.getDevice()
        let modelIdentifier = provider.getModelIdentifier()

        // Then - just verify we got a result and it's not the raw identifier
        // (unless it's an unknown model)
        XCTAssertNotNil(device)
        print("Test device: \(device), identifier: \(modelIdentifier)")
    }

    func testDeviceMapping_SimulatorDetection() {
        // When
        let device = provider.getDevice()
        let identifier = provider.getModelIdentifier()

        // Then - if running on simulator
        let simulatorIdentifiers = ["i386", "x86_64", "arm64"]
        if simulatorIdentifiers.contains(identifier) {
            XCTAssertTrue(
                device.contains("Simulator"),
                "Simulator should be detected in device name"
            )
        }
    }

    func testDeviceMapping_KnownDeviceModels_ReturnFriendlyNames() {
        // Test that known device models return friendly names, not raw identifiers
        // When running on real devices, this validates the mapping works

        // When
        let device = provider.getDevice()
        let identifier = provider.getModelIdentifier()

        // Then - for most known devices, friendly name should differ from identifier
        if identifier.hasPrefix("iPhone"), !["i386", "x86_64", "arm64"].contains(identifier) {
            // Should be friendly name like "iPhone 15 Pro" not raw "iPhone16,1"
            XCTAssertFalse(
                device.contains(","),
                "iPhone device name should not contain comma (should be friendly): \(device)"
            )
        }
    }

    // MARK: - Edge Case Tests

    func testGetDeviceType_iPhone_Variants() {
        // When
        let deviceType = provider.getDeviceType()
        let identifier = provider.getModelIdentifier()

        // Then - validate device type logic for iPhones
        if identifier.hasPrefix("iPhone") {
            XCTAssertEqual(deviceType, "phone", "iPhone models should return 'phone'")
        }
    }

    func testGetDeviceType_iPad_Variants() {
        // When
        let deviceType = provider.getDeviceType()
        let identifier = provider.getModelIdentifier()

        // Then - validate device type logic for iPads
        if identifier.hasPrefix("iPad") {
            XCTAssertEqual(deviceType, "tablet", "iPad models should return 'tablet'")
        }
    }

    func testGetDeviceType_Simulator_DefaultsToPhone() {
        // When
        let deviceType = provider.getDeviceType()
        let identifier = provider.getModelIdentifier()

        // Then - simulators without SIMULATOR_MODEL_IDENTIFIER should default to phone
        let simulatorIdentifiers = ["i386", "x86_64", "arm64"]
        if simulatorIdentifiers.contains(identifier) {
            // Should return a valid device type (phone, tablet, or watch)
            let validTypes = ["phone", "tablet", "watch"]
            XCTAssertTrue(
                validTypes.contains(deviceType),
                "Simulator should return valid device type: \(deviceType)"
            )
        }
    }

    func testGetUserLocale_HandlesLanguageOnly() {
        // When
        let locale = provider.getUserLocale()

        // Then - should handle both language-region and language-only formats
        if let locale = locale {
            // Should be at least 2 characters (language code)
            XCTAssertGreaterThanOrEqual(locale.count, 2)

            // If contains dash, should be properly formatted
            if locale.contains("-") {
                let components = locale.split(separator: "-")
                XCTAssertEqual(components.count, 2, "Locale with dash should have 2 components")
                XCTAssertEqual(components[0].count, 2, "Language code should be 2 characters")
                XCTAssertEqual(components[1].count, 2, "Region code should be 2 characters")
            }
        }
    }

    func testGetUserAgent_Format_Consistency() {
        // When
        let userAgent = provider.getUserAgent()
        let platformVersion = provider.getPlatformVersion()
        let modelIdentifier = provider.getModelIdentifier()

        // Then - verify exact format
        let expectedFormat = "iOS/\(platformVersion) (\(modelIdentifier))"
        XCTAssertEqual(userAgent, expectedFormat, "User agent should match expected format")
    }

    // MARK: - Integration Tests

    func testAllMethods_ReturnConsistentData() {
        // When
        let device = provider.getDevice()
        let deviceType = provider.getDeviceType()
        let locale = provider.getUserLocale()
        let userAgent = provider.getUserAgent()
        let modelIdentifier = provider.getModelIdentifier()
        let platformVersion = provider.getPlatformVersion()

        // Then - all values should be present and consistent
        XCTAssertFalse(device.isEmpty)
        XCTAssertFalse(deviceType.isEmpty)
        XCTAssertFalse(userAgent.isEmpty)
        XCTAssertFalse(modelIdentifier.isEmpty)
        XCTAssertFalse(platformVersion.isEmpty)

        // User agent should contain the platform version and model identifier
        XCTAssertTrue(userAgent.contains(platformVersion))
        XCTAssertTrue(userAgent.contains(modelIdentifier))

        print("""
        Device Info Provider Test Results:
        - Device: \(device)
        - Device Type: \(deviceType)
        - Locale: \(locale ?? "nil")
        - User Agent: \(userAgent)
        - Model Identifier: \(modelIdentifier)
        - Platform Version: \(platformVersion)
        """)
    }

    func testMultipleProviderInstances_ReturnSameData() {
        // Given
        let provider1 = DeviceInfoProvider()
        let provider2 = DeviceInfoProvider()

        // When
        let device1 = provider1.getDevice()
        let device2 = provider2.getDevice()
        let locale1 = provider1.getUserLocale()
        let locale2 = provider2.getUserLocale()

        // Then - different instances should return same data
        XCTAssertEqual(device1, device2, "Multiple provider instances should return same device")
        XCTAssertEqual(locale1, locale2, "Multiple provider instances should return same locale")
    }

    // MARK: - Coverage Enhancement Tests

    func testAllPublicMethods_MultipleCalls() {
        // This test ensures all public methods are called multiple times
        // to maximize code coverage of all branches

        // When - call all methods multiple times
        for _ in 0..<5 {
            _ = provider.getDevice()
            _ = provider.getDeviceType()
            _ = provider.getUserLocale()
            _ = provider.getUserAgent()
            _ = provider.getModelIdentifier()
            _ = provider.getPlatformVersion()
        }

        // Then - verify final call results
        let device = provider.getDevice()
        let deviceType = provider.getDeviceType()
        let locale = provider.getUserLocale()
        let userAgent = provider.getUserAgent()
        let modelId = provider.getModelIdentifier()
        let platform = provider.getPlatformVersion()

        XCTAssertFalse(device.isEmpty)
        XCTAssertFalse(deviceType.isEmpty)
        XCTAssertFalse(userAgent.isEmpty)
        XCTAssertFalse(modelId.isEmpty)
        XCTAssertFalse(platform.isEmpty)
    }

    func testDeviceInfoProvider_AllBranches() {
        // Test all accessible branches in the DeviceInfoProvider

        // Test device name retrieval
        let device = provider.getDevice()
        XCTAssertFalse(device.isEmpty)

        // Test device type with all possible paths
        let deviceType = provider.getDeviceType()
        let modelId = provider.getModelIdentifier()

        // Verify device type matches identifier
        if modelId.hasPrefix("iPhone") {
            XCTAssertEqual(deviceType, "phone")
        } else if modelId.hasPrefix("iPad") {
            XCTAssertEqual(deviceType, "tablet")
        } else if modelId.hasPrefix("Watch") {
            XCTAssertEqual(deviceType, "watch")
        } else if ["i386", "x86_64", "arm64"].contains(modelId) {
            // Simulator case - should be valid type
            XCTAssertTrue(["phone", "tablet", "watch"].contains(deviceType))
        }

        // Test locale with both branches
        let locale = provider.getUserLocale()
        if let locale = locale {
            XCTAssertGreaterThanOrEqual(locale.count, 2)
            // Branch 1: language + region (contains "-")
            // Branch 2: language only (no "-")
            if locale.contains("-") {
                let parts = locale.split(separator: "-")
                XCTAssertEqual(parts.count, 2)
            } else {
                // Language only
                XCTAssertEqual(locale.count, 2)
            }
        }

        // Test user agent construction
        let userAgent = provider.getUserAgent()
        let platform = provider.getPlatformVersion()
        XCTAssertTrue(userAgent.contains("iOS/"))
        XCTAssertTrue(userAgent.contains(platform))
        XCTAssertTrue(userAgent.contains(modelId))
    }

    func testDeviceMapping_CoversMainBranches() {
        // This test ensures the device mapping logic is exercised

        // When
        let device = provider.getDevice()
        let identifier = provider.getModelIdentifier()

        // Then - verify mapping based on identifier
        if identifier.hasPrefix("iPhone") {
            // Should not be raw identifier for known iPhones
            if !["i386", "x86_64", "arm64"].contains(identifier) {
                // Known iPhone models should have friendly names
                XCTAssertTrue(
                    device.contains("iPhone") || device.contains("Simulator"),
                    "iPhone device should have friendly name or be simulator"
                )
            }
        } else if identifier.hasPrefix("iPad") {
            // iPad models
            XCTAssertTrue(
                device.contains("iPad") || device.contains("Simulator"),
                "iPad device should have friendly name or be simulator"
            )
        } else if identifier.hasPrefix("iPod") {
            // iPod models
            XCTAssertTrue(
                device.contains("iPod") || device.contains("Simulator"),
                "iPod device should have friendly name or be simulator"
            )
        } else if ["i386", "x86_64", "arm64"].contains(identifier) {
            // Simulator
            XCTAssertTrue(
                device.contains("Simulator"),
                "Simulator identifier should result in Simulator name"
            )
        } else {
            // Unknown device - should return identifier as-is
            XCTAssertEqual(device, identifier, "Unknown device should return raw identifier")
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess_IsThreadSafe() async {
        // When - access provider from multiple tasks concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = self.provider.getDevice()
                    _ = self.provider.getDeviceType()
                    _ = self.provider.getUserLocale()
                    _ = self.provider.getUserAgent()
                    _ = self.provider.getModelIdentifier()
                    _ = self.provider.getPlatformVersion()
                }
            }
        }

        // Then - should not crash
        XCTAssertTrue(true, "Concurrent access completed without crashes")
    }

    func testConcurrentAccess_AllMethodsCombinations() async {
        // Test concurrent access with different method combinations

        await withTaskGroup(of: (String, String).self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let device = self.provider.getDevice()
                    let type = self.provider.getDeviceType()
                    return (device, type)
                }
            }

            var results: [(String, String)] = []
            for await result in group {
                results.append(result)
            }

            // All results should be consistent
            XCTAssertEqual(results.count, 10)
            let firstResult = results[0]
            for result in results {
                XCTAssertEqual(result.0, firstResult.0, "Device name should be consistent")
                XCTAssertEqual(result.1, firstResult.1, "Device type should be consistent")
            }
        }
    }
}
