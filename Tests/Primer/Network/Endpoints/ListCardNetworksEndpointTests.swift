//
//  ListCardNetworksEndpointTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class ListCardNetworksEndpointTests: XCTestCase {

    var networkService: MockNetworkService!

    var apiClient: PrimerAPIClientProtocol!

    override func setUp() {
        super.setUp()
        networkService = MockNetworkService()
        apiClient = PrimerAPIClient(networkService: networkService)
    }

    override func tearDown() {
        apiClient = nil
        networkService = nil
        super.tearDown()
    }

    func testValidRequestWithSuccessResponse() throws {

        let bin = "1234 5678 1234"
        let network = Response.Body.Bin.Networks.Network(value: "Test")

        let expectSuccessfulResponse = self.expectation(description: "Expect request to complete successfully")

        let expectValidEndpointReceived = self.expectation(description: "Expect endpoint to be valid")

        networkService.onReceiveEndpoint = { endpoint in
            XCTAssertEqual(endpoint.path, "/v1/bin-data/\(bin)/networks")
            XCTAssertEqual(endpoint.headers?["X-Api-Version"], "2.4")
            XCTAssertEqual(endpoint.headers?["Primer-Client-Token"], mockClientToken.accessToken)
            expectValidEndpointReceived.fulfill()
        }

        networkService.mockedResult = Response.Body.Bin.Networks(networks: [network])

        _ = apiClient.listCardNetworks(clientToken: mockClientToken, bin: bin) { result in
            switch result {
            case let .success(result):
                XCTAssertEqual(result.networks, [network])
                expectSuccessfulResponse.fulfill()
            case .failure:
                XCTFail("Expected successful response")
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testValidRequestWithErrorResponse() throws {

        let bin = "1234 5678 1234"

        let expectSuccessfulResponse = self.expectation(description: "Expect request to complete successfully")

        let expectValidEndpointReceived = self.expectation(description: "Expect endpoint to be valid")

        networkService.onReceiveEndpoint = { endpoint in
            XCTAssertEqual(endpoint.path, "/v1/bin-data/\(bin)/networks")
            XCTAssertEqual(endpoint.headers?["X-Api-Version"], "2.4")
            XCTAssertEqual(endpoint.headers?["Primer-Client-Token"], mockClientToken.accessToken)
            expectValidEndpointReceived.fulfill()
        }

        networkService.mockedError = NSError(domain: "", code: 123)

        _ = apiClient.listCardNetworks(clientToken: mockClientToken, bin: bin) { result in
            switch result {
            case .success:
                XCTFail("Expected failure with error response")
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, 123)
                expectSuccessfulResponse.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

}

extension Response.Body.Bin.Networks.Network: @retroactive Equatable {
    public static func == (lhs: PrimerSDK.Response.Body.Bin.Networks.Network, rhs: PrimerSDK.Response.Body.Bin.Networks.Network) -> Bool {
            lhs.value == rhs.value
    }
}
