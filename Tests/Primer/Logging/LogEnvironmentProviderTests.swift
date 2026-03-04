//
//  LogEnvironmentProviderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class LogEnvironmentProviderTests: XCTestCase {

    // MARK: - Test Endpoint URL Mapping

    func test_getEndpointURL_forDevEnvironment_returnsCorrectURL() {
        // Given: DEV environment
        let environment = AnalyticsEnvironment.dev

        // When: Getting endpoint URL
        let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)

        // Then: Should return DEV endpoint
        XCTAssertEqual(endpointURL.absoluteString, "https://analytics.dev.data.primer.io/v1/sdk-logs")
    }

    func test_getEndpointURL_forStagingEnvironment_returnsCorrectURL() {
        // Given: STAGING environment
        let environment = AnalyticsEnvironment.staging

        // When: Getting endpoint URL
        let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)

        // Then: Should return STAGING endpoint
        XCTAssertEqual(endpointURL.absoluteString, "https://analytics.staging.data.primer.io/v1/sdk-logs")
    }

    func test_getEndpointURL_forSandboxEnvironment_returnsCorrectURL() {
        // Given: SANDBOX environment
        let environment = AnalyticsEnvironment.sandbox

        // When: Getting endpoint URL
        let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)

        // Then: Should return SANDBOX endpoint
        XCTAssertEqual(endpointURL.absoluteString, "https://analytics.sandbox.data.primer.io/v1/sdk-logs")
    }

    func test_getEndpointURL_forProductionEnvironment_returnsCorrectURL() {
        // Given: PRODUCTION environment
        let environment = AnalyticsEnvironment.production

        // When: Getting endpoint URL
        let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)

        // Then: Should return PRODUCTION endpoint
        XCTAssertEqual(endpointURL.absoluteString, "https://analytics.production.data.primer.io/v1/sdk-logs")
    }

    func test_getEndpointURL_allEnvironments_returnValidURLs() {
        // Given: All environment cases
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then: Each environment should return a valid URL
        for environment in environments {
            let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)
            XCTAssertNotNil(endpointURL)
            XCTAssertTrue(endpointURL.absoluteString.hasPrefix("https://analytics."))
            XCTAssertTrue(endpointURL.absoluteString.hasSuffix("/v1/sdk-logs"))
        }
    }

    func test_getEndpointURL_allEnvironments_useHTTPS() {
        // Given: All environment cases
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then: All URLs should use HTTPS
        for environment in environments {
            let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)
            XCTAssertEqual(endpointURL.scheme, "https")
        }
    }

    func test_getEndpointURL_allEnvironments_haveCorrectPath() {
        // Given: All environment cases
        let environments: [AnalyticsEnvironment] = [.dev, .staging, .sandbox, .production]

        // When/Then: All URLs should have /v1/sdk-logs path
        for environment in environments {
            let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)
            XCTAssertEqual(endpointURL.path, "/v1/sdk-logs")
        }
    }

    func test_getEndpointURL_allEnvironments_haveCorrectHost() {
        // Given: All environment cases with expected hosts
        let environmentHosts: [(AnalyticsEnvironment, String)] = [
            (.dev, "analytics.dev.data.primer.io"),
            (.staging, "analytics.staging.data.primer.io"),
            (.sandbox, "analytics.sandbox.data.primer.io"),
            (.production, "analytics.production.data.primer.io")
        ]

        // When/Then: Each environment should have correct host
        for (environment, expectedHost) in environmentHosts {
            let endpointURL = LogEnvironmentProvider.getEndpointURL(for: environment)
            XCTAssertEqual(endpointURL.host, expectedHost)
        }
    }
}
