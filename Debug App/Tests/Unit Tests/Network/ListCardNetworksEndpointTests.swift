//
//  ListCardNetworksEndpointTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 17/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

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
        let network = Response.Body.Bin.Networks.Network(displayName: "Test", value: "Test")
        
        let expectSuccessfulResponse = self.expectation(description: "Expect request to complete successfully")
        
        let expectValidEndpointReceived = self.expectation(description: "Expect endpoint to be valid")
        
        networkService.onReceiveEndpoint = { endpoint in
            XCTAssertEqual(endpoint.path, "/bin-data/\(bin)/networks")
            XCTAssertEqual(endpoint.headers?["X-Api-Version"], "2.1")
            XCTAssertEqual(endpoint.headers?["Primer-Client-Token"], mockClientToken.accessToken)
            expectValidEndpointReceived.fulfill()
        }
        
        networkService.mockedResult = Response.Body.Bin.Networks(networks: [network])
        
        apiClient.listCardNetworks(clientToken: mockClientToken, bin: bin) { result in
            switch result {
            case .success(let result):
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
            XCTAssertEqual(endpoint.path, "/bin-data/\(bin)/networks")
            XCTAssertEqual(endpoint.headers?["X-Api-Version"], "2.1")
            XCTAssertEqual(endpoint.headers?["Primer-Client-Token"], mockClientToken.accessToken)
            expectValidEndpointReceived.fulfill()
        }
        
        networkService.mockedError = NSError(domain: "", code: 123)
        
        apiClient.listCardNetworks(clientToken: mockClientToken, bin: bin) { result in
            switch result {
            case .success:
                XCTFail("Expected failure with error response")
            case .failure(let error):
                XCTAssertEqual((error as NSError).code, 123)
                expectSuccessfulResponse.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }

}

extension Response.Body.Bin.Networks.Network: Equatable {
    public static func == (lhs: PrimerSDK.Response.Body.Bin.Networks.Network, rhs: PrimerSDK.Response.Body.Bin.Networks.Network) -> Bool {
        return lhs.displayName == rhs.displayName &&
        lhs.value == rhs.value
    }
}
