//
//  PrimerAPIConfigurationModuleTests.swift
//  ExampleAppTests
//
//  Created by Evangelos on 22/9/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class PrimerAPIConfigurationModuleTests: XCTestCase {

    override func tearDown() {
        ConfigurationCache.shared.clearCache()
    }

    func test_successful_api_configuration_setup() throws {
        let expectation = XCTestExpectation(description: "Poll URL | Success")

        let mockPrimerAPIConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.validateClientTokenResult = (SuccessResponse(), nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerAPIConfiguration, nil)

        PrimerAPIConfigurationModule.apiClient = mockApiClient

        let apiConfigurationModule = PrimerAPIConfigurationModule()

        firstly {
            apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)
        }
        .done {
            XCTAssert(MockAppState.mockClientToken == PrimerAPIConfigurationModule.clientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == mockPrimerAPIConfiguration.coreUrl)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.pciUrl == mockPrimerAPIConfiguration.pciUrl)
            expectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func test_usesCachedConfig() throws {
        let expectation = XCTestExpectation(description: "Uses Cached Config")
        let headlessExpectation = self.expectation(description: "Headless Loaded")

        let proxyId = "proxy-identifier"

        let settings = PrimerSettings(clientSessionCachingEnabled: true)
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", settings: settings) { paymentMethods, err in
            headlessExpectation.fulfill()
        }

        wait(for: [headlessExpectation])
        let config_pre = PrimerAPIConfiguration(
            coreUrl: proxyId,
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)

        let config_post = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)

        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.validateClientTokenResult = (SuccessResponse(), nil)
        mockApiClient.fetchConfigurationResult = (config_pre, nil)

        PrimerAPIConfigurationModule.apiClient = mockApiClient

        let apiConfigurationModule = PrimerAPIConfigurationModule()

        firstly {
            apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)
        }
        .then { () -> Promise<Void> in
            XCTAssert(MockAppState.mockClientToken == PrimerAPIConfigurationModule.clientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)

            mockApiClient.fetchConfigurationResult = (config_post, nil)

            return apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)
        }
        .done {
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            expectation.fulfill()

        }.catch { err in
            XCTAssert(false, err.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func test_clearsCache() throws {
        let expectation = XCTestExpectation(description: "Uses Cached Config")

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
            checkoutModules: nil)

        let config_post = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)

        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.validateClientTokenResult = (SuccessResponse(), nil)
        mockApiClient.fetchConfigurationResult = (config_pre, nil)

        PrimerAPIConfigurationModule.apiClient = mockApiClient

        let apiConfigurationModule = PrimerAPIConfigurationModule()

        firstly {
            apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)
        }
        .then { () -> Promise<Void> in
            XCTAssert(MockAppState.mockClientToken == PrimerAPIConfigurationModule.clientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            ConfigurationCache.shared.clearCache()

            mockApiClient.fetchConfigurationResult = (config_post, nil)

            return apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)
        }
        .done {
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_post.coreUrl)
            expectation.fulfill()
        }.catch { err in
            XCTAssert(false, err.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func test_actionsUsesCache() throws {
        let expectation = XCTestExpectation(description: "Uses Cached Config")

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
            checkoutModules: nil)

        let config_post = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)

        let mockApiClient = MockPrimerAPIClient(responseHeaders: [ConfigurationCachedData.CacheHeaderKey: "3600"])
        mockApiClient.validateClientTokenResult = (SuccessResponse(), nil)

        mockApiClient.fetchConfigurationResult = (config_pre, nil)
        mockApiClient.fetchConfigurationWithActionsResult = (config_post, nil)

        PrimerAPIConfigurationModule.apiClient = mockApiClient

        let apiConfigurationModule = PrimerAPIConfigurationModule()

        firstly {
            apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)
        }
        .then { () -> Promise<Void> in
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_pre.coreUrl)
            return apiConfigurationModule.updateSession(withActions: ClientSessionUpdateRequest(actions: ClientSessionAction(actions: [ClientSession.Action(type: .selectPaymentMethod, params: ["":""])])))
        }
        .then { () -> Promise<Void> in
            return apiConfigurationModule.setupSession(forClientToken: MockAppState.mockClientToken)
            XCTAssert(PrimerAPIConfigurationModule.apiConfiguration?.coreUrl == config_post.coreUrl)
        }
        .done {
            expectation.fulfill()
        }.catch { err in
            XCTAssert(false, err.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }
}

extension MockPrimerAPIClient {
    convenience init(responseHeaders: [String: String]) {
        self.init()
        self.responseHeaders = responseHeaders
    }
}
