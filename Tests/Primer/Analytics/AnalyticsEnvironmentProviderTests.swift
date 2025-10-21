//
//  AnalyticsEnvironmentProviderTests.swift
//  PrimerSDKTests
//
//  Tests for AnalyticsEnvironmentProvider
//

@testable import PrimerSDK
import XCTest

final class AnalyticsEnvironmentProviderTests: XCTestCase {

    private var provider: AnalyticsEnvironmentProvider!

    override func setUp() {
        super.setUp()
        provider = AnalyticsEnvironmentProvider()
    }

    override func tearDown() {
        provider = nil
        super.tearDown()
    }

    // MARK: - Dev Environment Tests

    func testGetEndpointURL_Dev_ReturnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .dev)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.dev.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func testGetEndpointURL_Dev_ReturnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .dev)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.dev.data.primer.io")
        XCTAssertEqual(url?.path, "/v1/sdk-analytic-events")
    }

    // MARK: - Staging Environment Tests

    func testGetEndpointURL_Staging_ReturnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .staging)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.staging.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func testGetEndpointURL_Staging_ReturnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .staging)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.staging.data.primer.io")
    }

    // MARK: - Sandbox Environment Tests

    func testGetEndpointURL_Sandbox_ReturnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .sandbox)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.sandbox.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func testGetEndpointURL_Sandbox_ReturnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .sandbox)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.sandbox.data.primer.io")
    }

    // MARK: - Production Environment Tests

    func testGetEndpointURL_Production_ReturnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .production)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.production.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func testGetEndpointURL_Production_ReturnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .production)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.production.data.primer.io")
    }

    // MARK: - All Environments Test

    func testGetEndpointURL_AllEnvironments_ReturnValidURLs() {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then
        for environment in environments {
            let url = provider.getEndpointURL(for: environment)
            XCTAssertNotNil(url, "URL should not be nil for \(environment.rawValue)")
            XCTAssertEqual(url?.scheme, "https", "Should use HTTPS for \(environment.rawValue)")
            XCTAssertTrue(
                url?.host?.contains("analytics") ?? false,
                "Host should contain 'analytics' for \(environment.rawValue)"
            )
            XCTAssertTrue(
                url?.host?.contains("primer.io") ?? false,
                "Host should contain 'primer.io' for \(environment.rawValue)"
            )
            XCTAssertEqual(
                url?.path,
                "/v1/sdk-analytic-events",
                "Path should be correct for \(environment.rawValue)"
            )
        }
    }

    // MARK: - URL Format Tests

    func testGetEndpointURL_AllEnvironments_UseHTTPS() {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then
        for environment in environments {
            let url = provider.getEndpointURL(for: environment)
            XCTAssertEqual(
                url?.scheme,
                "https",
                "All environments must use HTTPS: \(environment.rawValue)"
            )
        }
    }

    func testGetEndpointURL_AllEnvironments_HaveCorrectPath() {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]
        let expectedPath = "/v1/sdk-analytic-events"

        // When/Then
        for environment in environments {
            let url = provider.getEndpointURL(for: environment)
            XCTAssertEqual(
                url?.path,
                expectedPath,
                "Path should be '\(expectedPath)' for \(environment.rawValue)"
            )
        }
    }

    func testGetEndpointURL_AllEnvironments_HaveUniqueHosts() {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When
        let hosts = environments.compactMap { provider.getEndpointURL(for: $0)?.host }

        // Then
        let uniqueHosts = Set(hosts)
        XCTAssertEqual(
            hosts.count,
            uniqueHosts.count,
            "Each environment should have a unique host"
        )
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess_IsThreadSafe() async {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When - access provider from multiple tasks concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    for environment in environments {
                        _ = self.provider.getEndpointURL(for: environment)
                    }
                }
            }
        }

        // Then - should not crash
        XCTAssertTrue(true, "Concurrent access completed without crashes")
    }

    // MARK: - Integration Tests

    func testGetEndpointURL_AllEnvironments_PrintURLs() {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then
        print("\nAnalytics Environment URLs:")
        for environment in environments {
            if let url = provider.getEndpointURL(for: environment) {
                print("  \(environment.rawValue): \(url.absoluteString)")
                XCTAssertNotNil(url)
            }
        }
    }
}
