//
//  DefaultNetworkServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import PrimerFoundation
@testable import PrimerSDK

class MockRequestDispatcher: RequestDispatcher, @unchecked Sendable {

    var error: Error?

    var responseModel: DispatcherResponse!

    func dispatch(request: URLRequest) async throws -> any PrimerSDK.DispatcherResponse {
        if let error = error {
            throw error
        }
        return responseModel
    }

    func dispatch(
        request: URLRequest,
        completion: @escaping PrimerSDK.DispatcherCompletion
    ) -> (any PrimerCancellable)? {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(responseModel))
        }
        return nil
    }

    func dispatchWithRetry(
        request: URLRequest,
        retryConfig: PrimerSDK.RetryConfig,
        completion: @escaping DispatcherCompletion
    ) -> (any PrimerCancellable)? {
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

    func testBasicRequest_jsonDecodingSuccess_completion() throws {

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
            case let .success(model):
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
            case .failure:
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)

        waitForExpectations(timeout: 2.0)
    }

    func testBasicRequest_jsonDecodingSuccess_async() async throws {
        let responseModel = PrimerAPIConfiguration(
            coreUrl: "https://core_url",
            pciUrl: "https://pci_url",
            binDataUrl: "https://bin_data_url",
            assetsUrl: "https://assets_url",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: "primer_account_id",
            keys: nil,
            checkoutModules: []
        )

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = try JSONEncoder().encode(responseModel)
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let (model, headers): (PrimerAPIConfiguration, [String: String]?) = try await defaultNetworkService.request(endpoint)

        XCTAssertEqual(model.coreUrl, "https://core_url")
        XCTAssertEqual(headers?["X-Test-Key"], "X-Test-Value")
        XCTAssertEqual(model.pciUrl, "https://pci_url")
        XCTAssertEqual(model.binDataUrl, "https://bin_data_url")
        XCTAssertEqual(model.assetsUrl, "https://assets_url")
        XCTAssertEqual(model.primerAccountId, "primer_account_id")
        XCTAssertNil(model.clientSession)
        XCTAssertTrue(model.paymentMethods!.isEmpty)
        XCTAssertNil(model.keys)
        XCTAssertTrue(model.checkoutModules!.isEmpty)
    }

    func testBasicRequest_jsonDecodingFailure_completion() throws {

        let expectation = self.expectation(description: "Fails with decoding error")

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = try JSONEncoder().encode("invalid")
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<PrimerAPIConfiguration>) in
            switch result {
            case .success:
                XCTFail(); return
            case let .failure(error):
                switch error as! PrimerSDK.InternalError {
                case let .failedToDecode(message, _):
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

    func testBasicRequest_jsonDecodingFailure_async() async throws {
        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = try JSONEncoder().encode("invalid")
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        do {
            let (_, _): (PrimerAPIConfiguration, [String: String]?) = try await defaultNetworkService.request(endpoint)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error as! PrimerSDK.InternalError {
            case let .failedToDecode(message, _):
                XCTAssertEqual(message, "Failed to decode response of type \'Configuration\' from URL: https://response_url")
            default:
                XCTFail()
            }
        }
    }

    func testRedirectRequest_successWithEmptyResponse_completion() {
        let expectation = self.expectation(description: "Fails with decoding error")

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = Data()
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.redirect(clientToken: Mocks.decodedJWTToken, url: URL(string: metadata.responseUrl!)!)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<SuccessResponse>) in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)

        waitForExpectations(timeout: 2.0)
    }

    func testRedirectRequest_successWithEmptyResponse_async() async throws {
        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: Data(), error: nil)

        let endpoint = PrimerAPI.redirect(clientToken: Mocks.decodedJWTToken, url: URL(string: metadata.responseUrl!)!)
        let (_, headers): (SuccessResponse, [String: String]?) = try await defaultNetworkService.request(endpoint)

        XCTAssertEqual(headers?["X-Test-Key"], "X-Test-Value")
    }

    func testRedirectRequest_successWithNonJsonResponse_completion() {
        let expectation = self.expectation(description: "Fails with decoding error")

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = "<html><head></head><body><a>test</a></body></html>".data(using: .utf8)
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.redirect(clientToken: Mocks.decodedJWTToken, url: URL(string: metadata.responseUrl!)!)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<SuccessResponse>) in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)

        waitForExpectations(timeout: 2.0)
    }

    func testRedirectRequest_successWithNonJsonResponse_async() async throws {
        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = "<html><head></head><body><a>test</a></body></html>".data(using: .utf8)
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.redirect(clientToken: Mocks.decodedJWTToken, url: URL(string: metadata.responseUrl!)!)
        let (_, headers): (SuccessResponse, [String: String]?) = try await defaultNetworkService.request(endpoint)

        XCTAssertEqual(headers?["X-Test-Key"], "X-Test-Value")
    }

    func testRequest_failsDueToNetworkError_completion() {
        let expectation = self.expectation(description: "Fails with network error")

        requestDispatcher.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let cancellable = defaultNetworkService.request(endpoint) { (result: APIResult<PrimerAPIConfiguration>) in
            switch result {
            case .success:
                XCTFail("Expected failure due to network error")
            case let .failure(error):
                XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
                XCTAssertEqual((error as NSError).code, NSURLErrorNotConnectedToInternet)
                expectation.fulfill()
            }
        }

        XCTAssertNil(cancellable)
        waitForExpectations(timeout: 2.0)
    }

    func testRequest_failsDueToNetworkError_async() async throws {
        requestDispatcher.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        do {
            let (_, _): (PrimerAPIConfiguration, [String: String]?) = try await defaultNetworkService.request(endpoint)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
            XCTAssertEqual((error as NSError).code, NSURLErrorNotConnectedToInternet)
        }
    }

    func testRequest_withHeaders_success_completion() {
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
            case let .success(model):
                XCTAssertEqual(model.coreUrl, "https://core_url")
                XCTAssertEqual(headers?["X-Test-Key"], "X-Test-Value")
                expectation.fulfill()
            case .failure:
                XCTFail(); return
            }
        }

        XCTAssertNil(cancellable)
        waitForExpectations(timeout: 2.0)
    }

    func testRequest_withHeaders_success_async() async throws {
        let responseModel = PrimerAPIConfiguration(
            coreUrl: "https://core_url",
            pciUrl: "https://pci_url",
            binDataUrl: "https://bin_data_url",
            assetsUrl: "https://assets_url",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: "primer_account_id",
            keys: nil,
            checkoutModules: []
        )

        let metadata = ResponseMetadataModel(responseUrl: "https://response_url", statusCode: 200, headers: ["X-Test-Key": "X-Test-Value"])
        let data = try! JSONEncoder().encode(responseModel)
        requestDispatcher.responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: 1000, data: data, error: nil)

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: nil)
        let (model, headers): (PrimerAPIConfiguration, [String: String]?) = try await defaultNetworkService.request(endpoint)

        XCTAssertEqual(model.coreUrl, "https://core_url")
        XCTAssertEqual(headers?["X-Test-Key"], "X-Test-Value")
    }
}
