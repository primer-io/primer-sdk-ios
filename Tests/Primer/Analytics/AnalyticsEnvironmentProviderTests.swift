//
//  AnalyticsEnvironmentProviderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

    func test_getEndpointURL_dev_returnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .dev)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.dev.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func test_getEndpointURL_dev_returnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .dev)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.dev.data.primer.io")
        XCTAssertEqual(url?.path, "/v1/sdk-analytic-events")
    }

    // MARK: - Staging Environment Tests

    func test_getEndpointURL_staging_returnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .staging)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.staging.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func test_getEndpointURL_staging_returnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .staging)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.staging.data.primer.io")
    }

    // MARK: - Sandbox Environment Tests

    func test_getEndpointURL_sandbox_returnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .sandbox)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.sandbox.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func test_getEndpointURL_sandbox_returnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .sandbox)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.sandbox.data.primer.io")
    }

    // MARK: - Production Environment Tests

    func test_getEndpointURL_production_returnsCorrectURL() {
        // When
        let url = provider.getEndpointURL(for: .production)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(
            url?.absoluteString,
            "https://analytics.production.data.primer.io/v1/sdk-analytic-events"
        )
    }

    func test_getEndpointURL_production_returnsValidURL() {
        // When
        let url = provider.getEndpointURL(for: .production)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "analytics.production.data.primer.io")
    }

    // MARK: - All Environments Test

    func test_getEndpointURL_allEnvironments_returnValidURLs() {
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

    func test_getEndpointURL_allEnvironments_useHTTPS() {
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

    func test_getEndpointURL_allEnvironments_haveCorrectPath() {
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

    func test_getEndpointURL_allEnvironments_haveUniqueHosts() {
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

    func test_concurrentAccess_isThreadSafe() async {
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

    func test_getEndpointURL_allEnvironments_verifyURLs() {
        // Given
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then
        for environment in environments {
            let url = provider.getEndpointURL(for: environment)
            XCTAssertNotNil(url, "URL should not be nil for \(environment.rawValue)")
        }
    }
}
