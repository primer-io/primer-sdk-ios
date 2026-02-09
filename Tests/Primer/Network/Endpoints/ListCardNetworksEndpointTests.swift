//
//  ListCardNetworksEndpointTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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

        let expectSuccessfulResponse = self.expectation(description: "Expect request to complete successfully")

        let expectValidEndpointReceived = self.expectation(description: "Expect endpoint to be valid")

        networkService.onReceiveEndpoint = { endpoint in
            XCTAssertEqual(endpoint.path, "/v1/bin-data/\(bin)")
            XCTAssertEqual(endpoint.headers?["X-Api-Version"], "2.4")
            XCTAssertEqual(endpoint.headers?["Primer-Client-Token"], mockClientToken.accessToken)
            expectValidEndpointReceived.fulfill()
        }

        networkService.mockedResult = Response.Body.Bin.Data(
            firstDigits: "123456",
            binData: [.init(displayName: "Test",
                            network: "Test",
                            issuerCountryCode: nil,
                            issuerName: nil,
                            accountFundingType: nil,
                            prepaidReloadableIndicator: nil,
                            productUsageType: nil,
                            productCode: nil,
                            productName: nil,
                            issuerCurrencyCode: nil,
                            regionalRestriction: nil,
                            accountNumberType: nil)]
        )

        apiClient.listCardNetworks(clientToken: mockClientToken, bin: bin) { result in
            switch result {
            case let .success(result):
                XCTAssertEqual(result.networks, [Response.Body.Bin.Networks.Network(value: "Test")])
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
            XCTAssertEqual(endpoint.path, "/v1/bin-data/\(bin)")
            XCTAssertEqual(endpoint.headers?["X-Api-Version"], "2.4")
            XCTAssertEqual(endpoint.headers?["Primer-Client-Token"], mockClientToken.accessToken)
            expectValidEndpointReceived.fulfill()
        }

        networkService.mockedError = NSError(domain: "", code: 123)

        apiClient.listCardNetworks(clientToken: mockClientToken, bin: bin) { result in
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

    func testFetchBinDataWithSuccessResponse() async throws {
        let bin = "12345678"

        networkService.onReceiveEndpoint = { endpoint in
            XCTAssertEqual(endpoint.path, "/v1/bin-data/\(bin)")
        }

        networkService.mockedResult = Response.Body.Bin.Data(
            firstDigits: "123456",
            binData: [.init(displayName: "Visa",
                            network: "VISA",
                            issuerCountryCode: "US",
                            issuerName: "Chase",
                            accountFundingType: "DEBIT",
                            prepaidReloadableIndicator: nil,
                            productUsageType: nil,
                            productCode: nil,
                            productName: nil,
                            issuerCurrencyCode: "USD",
                            regionalRestriction: nil,
                            accountNumberType: nil)]
        )

        let result = try await apiClient.fetchBinData(clientToken: mockClientToken, bin: bin)
        XCTAssertEqual(result.firstDigits, "123456")
        XCTAssertEqual(result.binData.count, 1)
        XCTAssertEqual(result.binData[0].network, "VISA")
        XCTAssertEqual(result.binData[0].issuerCountryCode, "US")
        XCTAssertEqual(result.binData[0].issuerName, "Chase")
    }

}

extension Response.Body.Bin.Networks.Network: Equatable {
    public static func == (lhs: PrimerSDK.Response.Body.Bin.Networks.Network, rhs: PrimerSDK.Response.Body.Bin.Networks.Network) -> Bool {
            lhs.value == rhs.value
    }
}
