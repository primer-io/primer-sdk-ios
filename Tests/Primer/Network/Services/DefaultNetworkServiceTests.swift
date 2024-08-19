//
//  DefaultNetworkServiceTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 28/03/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class MockRequestDispatcher: RequestDispatcher {

    var error: Error?

    var responseModel: DispatcherResponse!

    func dispatch(request: URLRequest) async throws -> any PrimerSDK.DispatcherResponse {
        if let error = error {
            throw error
        }
        return responseModel
    }
    
    func dispatch(request: URLRequest, completion: @escaping PrimerSDK.DispatcherCompletion) -> (any PrimerSDK.PrimerCancellable)? {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(responseModel))
        }
        return nil
    }

    func dispatchWithRetry(request: URLRequest, retryConfig: PrimerSDK.RetryConfig, completion: @escaping PrimerSDK.DispatcherCompletion) -> (any PrimerSDK.PrimerCancellable)? {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(responseModel))
        }
        return nil
    }
}

final class DefaultNetworkServiceTests: XCTestCase {

    var requestDispatcher: MockRequestDispatcher!

    var defaultNetworkService: DefaultNetworkService!

    override func setUpWithError() throws {
        requestDispatcher = MockRequestDispatcher()
        defaultNetworkService = DefaultNetworkService(requestFactory: DefaultNetworkRequestFactory(),
                                                      requestDispatcher: requestDispatcher,
                                                      reportingService: DefaultNetworkReportingService())
    }

    override func tearDownWithError() throws {
        defaultNetworkService = nil
        requestDispatcher = nil
    }

    func testBasicRequest_jsonDecodingSuccess_sync() throws {

        let expectation = self.expectation(description: "Successful response")

        let responseModel = PrimerAPIConfiguration(coreUrl: "https://core_url",
                                                   pciUrl: "https://pci_url",
                                                   binDataUrl: "https://bin_data_url",
                                                   assetsUrl: "https://assets_url",
                                                   clientSession: nil,
                                                   paymentMethods: [],
                                                   primerAccountId: "primer_account_id",
                                                   keys: nil,
                                                   checkoutModules: [])

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = try JSONEncoder().encode(responseModel)
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<PrimerAPIConfiguration>) in
            switch result {
            case .success(let model):
                XCTAssertEqual(model.coreUrl, "https://core_url")
                XCTAssertEqual(model.pciUrl, "https://pci_url")
                XCTAssertEqual(model.binDataUrl, "https://bin_data_url")
                XCTAssertEqual(model.assetsUrl, "https://assets_url")
                XCTAssertEqual(model.primerAccountId, "primer_account_id")
                XCTAssertNil(model.clientSession)
                XCTAssertTrue(model.paymentMethods!.isEmpty)
                XCTAssertNil(model.keys)
                XCTAssertTrue(model.checkoutModules!.isEmpty)
                expectation.fulfill()
            case .failure(_):
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)

        waitForExpectations(timeout: 2.0)
    }

    func testBasicRequest_jsonDecodingFailure_sync() throws {

        let expectation = self.expectation(description: "Fails with decoding error")

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = try JSONEncoder().encode("invalid")
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<PrimerAPIConfiguration>) in
            switch result {
            case .success(_):
                XCTFail(); return
            case .failure(let error):
                switch error as! PrimerSDK.InternalError {
                case .failedToDecode(let message, _, _):
                    XCTAssertEqual(message, "Failed to decode response of type \'Configuration\' from URL: https://response_url")
                default:
                    XCTFail()
                }
                expectation.fulfill()
            }
        }

        XCTAssertNil(cancellable)

        waitForExpectations(timeout: 2.0)

    }

    func testRedirectRequest_successWithEmptyResponse_sync() {
        let expectation = self.expectation(description: "Fails with decoding error")

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = Data()
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.redirect(clientToken: Mocks.decodedJWTToken, url: URL(string: metadata.responseUrl!)!)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<SuccessResponse>) in
            switch result {
            case .success(_):
                expectation.fulfill()
            case .failure(_):
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)

        waitForExpectations(timeout: 2.0)
    }

    func testRedirectRequest_successWithNonJsonResponse_sync() {
        let expectation = self.expectation(description: "Fails with decoding error")

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = "<html><head></head><body><a>test</a></body></html>".data(using: .utf8)
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.redirect(clientToken: Mocks.decodedJWTToken, url: URL(string: metadata.responseUrl!)!)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<SuccessResponse>) in
            switch result {
            case .success(_):
                expectation.fulfill()
            case .failure(_):
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)

        waitForExpectations(timeout: 2.0)
    }

    func testRequest_failsDueToNetworkError_sync() {
        let expectation = self.expectation(description: "Fails with network error")

        requestDispatcher.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<PrimerAPIConfiguration>) in
            switch result {
            case .success(_):
                XCTFail("Expected failure due to network error")
            case .failure(let error):
                XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
                XCTAssertEqual((error as NSError).code, NSURLErrorNotConnectedToInternet)
                expectation.fulfill()
            }
        }

        XCTAssertNil(cancellable)
        waitForExpectations(timeout: 2.0)
    }

    func testRequest_withHeaders_success_sync() {
        let expectation = self.expectation(description: "Successful response with headers")

        let responseModel = PrimerAPIConfiguration(coreUrl: "https://core_url",
                                                   pciUrl: "https://pci_url",
                                                   binDataUrl: "https://bin_data_url",
                                                   assetsUrl: "https://assets_url",
                                                   clientSession: nil,
                                                   paymentMethods: [],
                                                   primerAccountId: "primer_account_id",
                                                   keys: nil,
                                                   checkoutModules: [])

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = try! JSONEncoder().encode(responseModel)
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<PrimerAPIConfiguration>, headers: [String: String]?) in
            switch result {
            case .success(let model):
                XCTAssertEqual(model.coreUrl, "https://core_url")
                XCTAssertEqual(headers?["X-Test-Key"], "X-Test-Value")
                expectation.fulfill()
            case .failure(_):
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)
        waitForExpectations(timeout: 2.0)
    }
}
