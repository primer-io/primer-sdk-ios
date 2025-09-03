//
//  PrimerAPIConfigurationModuleTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class PrimerAPIConfigurationModuleTests: XCTestCase {
    override func tearDown() {
        ConfigurationCache.shared.clearCache()
    }

    /// Tests that `setupSession` succeeds when provided with a valid configuration.
    /// Caching is not relevant for this test.
    func test_setupSession_succeedsWithValidConfiguration() async throws {
        // Mock the configuration
        let config = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        // Create a mock ApiClient and set it to the configuration module as a static property
        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.validateClientTokenResult = (SuccessResponse(), nil)
        mockApiClient.fetchConfigurationResult = (config, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        // Create ApiConfigurationModule
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        // Create an expectation for the async operation
        let asyncExpectation = XCTestExpectation(description: "Async operation completes successfully")

        do {
            // Call the async function
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify the configuration
            XCTAssertEqual(PrimerAPIConfigurationModule.clientToken, MockAppState.mockClientToken, "Client token should match the mock token.")
            XCTAssertEqual(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl, config.coreUrl, "Core URL should match the mock configuration.")
            XCTAssertEqual(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl, config.pciUrl, "PCI URL should match the mock configuration.")
            XCTAssertEqual(
                PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl,
                config.binDataUrl,
                "Bin Data URL should match the mock configuration."
            )
            XCTAssertEqual(
                PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl,
                config.assetsUrl,
                "Assets URL should match the mock configuration."
            )
            // Fulfill the expectation
            asyncExpectation.fulfill()
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            asyncExpectation.fulfill()
        }
    }

    /// Tests that `setupSession` fails when the configuration fetch returns an error.
    /// Caching is not relevant for this test.
    func test_setupSession_failsWithInvalidConfiguration() async throws {
        let setupSessionExpectation = XCTestExpectation(description: "Setup session fails with error")

        // Create a mock ApiClient and set it to the configuration module as a static property
        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.fetchConfigurationResult = (nil,
                                                  NSError(
                                                      domain: "com.primer.sdk",
                                                      code: 500,
                                                      userInfo: [NSLocalizedDescriptionKey: "Failed to fetch configuration."]
                                                  ))
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        // Create ApiConfigurationModule
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        do {
            // Call the async function
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // This block should not be executed since we expect an error
            XCTFail("Expected error but got success.")

            setupSessionExpectation.fulfill()
        } catch {
            // Verify the error
            XCTAssertEqual(error.localizedDescription, "Failed to fetch configuration.", "Error message should match the mock error.")

            setupSessionExpectation.fulfill()
        }
    }

    /// Tests that `setupSession` uses the cached configuration when caching is enabled.
    /// Caching is enabled for this test.
    func test_setupSession_usesCachedConfigurationWhenCachingIsEnabled() async throws {
        let setupSessionExpectation = XCTestExpectation(description: "Setup session completes successfully")

        // Start the headless
        let settings = PrimerSettings(clientSessionCachingEnabled: true)
        do {
            let _ = try await PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", settings: settings)
        } catch {
            // We expect this to fail because the client token is empty
            XCTAssertTrue(error.localizedDescription.lowercased().contains("client token is not valid"))
        }

        // Mock the configuration
        let proxyId = "proxy-identifier"
        let config_pre = PrimerAPIConfiguration(
            coreUrl: proxyId,
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        let config_post = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        // Create a mock ApiClient and set it to the configuration module as a static property
        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.fetchConfigurationResult = (config_pre, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        // Create ApiConfigurationModule
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        do {
            // Call the async function
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify the cached configuration
            XCTAssert(PrimerAPIConfigurationModule.clientToken == MockAppState.mockClientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_pre.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_pre.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_pre.assetsUrl)

            // Update the fetch method to simulate a new configuration
            mockApiClient.fetchConfigurationResult = (config_post, nil)

            // Trigger the setupSession again to fetch the new configuration
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify that the cached configuration is still being used when caching is enabled
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_pre.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_pre.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_pre.assetsUrl)

            setupSessionExpectation.fulfill()
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            setupSessionExpectation.fulfill()
        }
    }

    /// Tests that `setupSession` fetches a new configuration when caching is disabled.
    /// Caching is disabled for this test.
    func test_setupSession_fetchesUpdatedConfigurationWhenCachingIsDisabled() async throws {
        let setupSessionExpectation = XCTestExpectation(description: "Setup session completes successfully")

        // Start the headless
        let settings = PrimerSettings(clientSessionCachingEnabled: false)
        do {
            let _ = try await PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", settings: settings)
        } catch {
            // We expect this to fail because the client token is empty
            XCTAssertTrue(error.localizedDescription.lowercased().contains("client token is not valid"))
        }

        // Mock the configuration
        let proxyId = "proxy-identifier"
        let config_pre = PrimerAPIConfiguration(
            coreUrl: proxyId,
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        let config_post = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        // Create a mock ApiClient and set it to the configuration module as a static property
        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.fetchConfigurationResult = (config_pre, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        // Create ApiConfigurationModule
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        do {
            // Call the async function
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify the cached configuration
            XCTAssert(PrimerAPIConfigurationModule.clientToken == MockAppState.mockClientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_pre.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_pre.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_pre.assetsUrl)

            // Update the fetch method to simulate a new configuration
            mockApiClient.fetchConfigurationResult = (config_post, nil)

            // Trigger the setupSession again to fetch the new configuration
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify that the updated configuration is still being used when caching is disabled
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_post.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_post.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_post.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_post.assetsUrl)

            setupSessionExpectation.fulfill()
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            setupSessionExpectation.fulfill()
        }
    }

    /// Tests that `setupSession` fetches a new configuration after the cache is cleared.
    /// Caching is enabled initially but cleared during the test.
    func test_setupSession_fetchesUpdatedConfigurationAfterCacheIsCleared() async throws {
        let setupSessionExpectation = XCTestExpectation(description: "Setup session completes successfully")

        // Start the headless
        let settings = PrimerSettings(clientSessionCachingEnabled: true)
        do {
            let _ = try await PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", settings: settings)
        } catch {
            // We expect this to fail because the client token is empty
            XCTAssertTrue(error.localizedDescription.lowercased().contains("client token is not valid"))
        }

        // Mock the configuration
        let proxyId = "proxy-identifier"
        let config_pre = PrimerAPIConfiguration(
            coreUrl: proxyId,
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        let config_post = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        // Create a mock ApiClient and set it to the configuration module as a static property
        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.fetchConfigurationResult = (config_pre, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        // Create ApiConfigurationModule
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        do {
            // Call the async function
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify the cached configuration
            XCTAssert(PrimerAPIConfigurationModule.clientToken == MockAppState.mockClientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_pre.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_pre.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_pre.assetsUrl)

            // Clear the cache
            ConfigurationCache.shared.clearCache()

            // Update the fetch method to simulate a new configuration
            mockApiClient.fetchConfigurationResult = (config_post, nil)

            // Trigger the setupSession again to fetch the new configuration
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify that the updated configuration is being used after clearing the cache
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_post.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_post.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_post.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_post.assetsUrl)

            setupSessionExpectation.fulfill()
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            setupSessionExpectation.fulfill()
        }
    }

    /// Tests that `setupSession` updates the configuration when an action is triggered.
    /// Caching is enabled for this test.
    func test_setupSession_updatesConfigurationWhenActionIsTriggered() async throws {
        let setupSessionExpectation = XCTestExpectation(description: "Setup session completes successfully")

        // Start the headless
        let settings = PrimerSettings(clientSessionCachingEnabled: true)
        do {
            let _ = try await PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", settings: settings)
        } catch {
            // We expect this to fail because the client token is empty
            XCTAssertTrue(error.localizedDescription.lowercased().contains("client token is not valid"))
        }

        // Mock the configuration
        let proxyId = "proxy-identifier"
        let config_pre = PrimerAPIConfiguration(
            coreUrl: proxyId,
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: .mock_pre,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        let config_post = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: .mock_post,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        // Create a mock ApiClient and set it to the configuration module as a static property
        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.fetchConfigurationResult = (config_pre, nil)
        mockApiClient.fetchConfigurationWithActionsResult = (config_post, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        // Create ApiConfigurationModule
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        do {
            // Call the async function
            try await apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)

            // Verify the configurations are matching with the config_pre
            XCTAssert(PrimerAPIConfigurationModule.clientToken == MockAppState.mockClientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_pre.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_pre.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_pre.assetsUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId == config_pre.clientSession?.clientSessionId)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.first?.type == config_pre.checkoutModules?.first?.type)

            try await apiConfigurationModule.updateSession(withActions:
                ClientSessionUpdateRequest(actions: ClientSessionAction(actions: [ClientSession.Action(
                    type: .selectPaymentMethod,
                    params: ["": ""]
                )])))

            // Verify the configurations are still matching with the config_pre
            XCTAssert(PrimerAPIConfigurationModule.clientToken == MockAppState.mockClientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == config_pre.pciUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.binDataUrl == config_pre.binDataUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.assetsUrl == config_pre.assetsUrl)

            // Verify the configurations are updated with the config_post
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId == config_post.clientSession?.clientSessionId)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.first?.type == config_post.checkoutModules?.first?.type)

            setupSessionExpectation.fulfill()
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            setupSessionExpectation.fulfill()
        }
    }
}

extension MockPrimerAPIClient {
    convenience init(responseHeaders: [String: String]) {
        self.init()
        self.responseHeaders = responseHeaders
    }
}

extension ClientSession.APIResponse {
    static var mock_pre: ClientSession.APIResponse {
        .init(clientSessionId: "mock_pre", paymentMethod: nil, order: nil, customer: nil, testId: nil)
    }

    static var mock_post: ClientSession.APIResponse {
        .init(clientSessionId: "mock_post", paymentMethod: nil, order: nil, customer: nil, testId: nil)
    }
}

extension Response.Body.Configuration.CheckoutModule {
    static var mock_pre: Response.Body.Configuration.CheckoutModule {
        .init(type: "mock_pre", requestUrlStr: nil, options: nil)
    }

    static var mock_post: Response.Body.Configuration.CheckoutModule {
        .init(type: "mock_post", requestUrlStr: nil, options: nil)
    }
}
