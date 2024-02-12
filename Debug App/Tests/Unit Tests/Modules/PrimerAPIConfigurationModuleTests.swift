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

    func test_successful_api_configuration_setup() throws {
        let expectation = XCTestExpectation(description: "Poll URL | Success")

        let mockPrimerAPIConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.validateClientTokenResult = (SuccessResponse(success: true), nil)
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
}
