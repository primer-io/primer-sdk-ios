//
//  RequestDispatcherTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class StubURLSessionDataTask: URLSessionDataTask {
    override func resume() {}
}

class MockURLSession: URLSessionProtocol {

    var data: Data?

    var response: URLResponse?

    var error: Error?

    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
        completionHandler(data, response, error)

        return StubURLSessionDataTask()
    }

}

final class RequestDispatcherTests: XCTestCase {

    var session: MockURLSession!

    var dispatcher: RequestDispatcher!

    override func setUpWithError() throws {
        session = MockURLSession()
        dispatcher = DefaultRequestDispatcher(urlSession: session)
    }

    override func tearDownWithError() throws {
        dispatcher = nil
        session = nil
    }

    func testSuccessfulResponse_sync() throws {

        let expectation = self.expectation(description: "Successful response received")

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2", headerFields: nil)
        session.data = "Test".data(using: .utf8)

        let request = URLRequest(url: url)
        dispatcher.dispatch(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.metadata.responseUrl, "https://a_url")
                XCTAssertEqual(response.metadata.statusCode, 200)
                XCTAssertEqual(response.data, self.session.data)
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testHTTPFailureResponse_sync() throws {

        let expectation = self.expectation(description: "Successful response received")

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "2", headerFields: nil)
        session.data = "Test".data(using: .utf8)

        let request = URLRequest(url: url)
        dispatcher.dispatch(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.metadata.responseUrl, "https://a_url")
                XCTAssertEqual(response.metadata.statusCode, 500)
                XCTAssertEqual(response.data, self.session.data)
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testFailedDispatchResponse_sync() throws {
        let expectation = self.expectation(description: "Successful response received")

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.error = PrimerError.unknown()

        let request = URLRequest(url: url)
        dispatcher.dispatch(request: request) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.hasPrefix("[invalid-response] Invalid response received. Expected HTTP response."))
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testSuccessfulResponse_async() async throws {

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2", headerFields: nil)
        session.data = "Test".data(using: .utf8)

        let request = URLRequest(url: url)
        let response = try await dispatcher.dispatch(request: request)

        XCTAssertEqual(response.metadata.responseUrl, "https://a_url")
        XCTAssertEqual(response.metadata.statusCode, 200)
        XCTAssertEqual(response.data, self.session.data)
    }

    func testHTTPFailureResponse_async() async throws {

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "2", headerFields: nil)
        session.data = "Test".data(using: .utf8)

        let request = URLRequest(url: url)
        let response = try await dispatcher.dispatch(request: request)

        XCTAssertEqual(response.metadata.responseUrl, "https://a_url")
        XCTAssertEqual(response.metadata.statusCode, 500)
        XCTAssertEqual(response.data, self.session.data)
    }

    func testFailedDispatchResponse_async() async throws {
        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.error = PrimerError.unknown()

        let request = URLRequest(url: url)
        do {
            _ = try await dispatcher.dispatch(request: request)
        } catch {
            XCTAssertTrue(error.localizedDescription.hasPrefix("[invalid-response] Invalid response received. Expected HTTP response."))
        }
    }

    func testRetryOnNetworkError() throws {
        let expectation = self.expectation(description: "Retry on network error")

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.error = URLError(.notConnectedToInternet)

        let request = URLRequest(url: url)
        let retryConfig = RetryConfig(maxRetries: 3, initialBackoff: 0.1, retryNetworkErrors: true, retry500Errors: false, maxJitter: 0.1)

        _ = dispatcher.dispatchWithRetry(request: request, retryConfig: retryConfig) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertEqual(self.session.error as? URLError, URLError(.notConnectedToInternet))
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testRetryOn500Error() throws {
        let expectation = self.expectation(description: "Retry on 500 error")

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "2", headerFields: nil)
        session.data = "Test".data(using: .utf8)

        let request = URLRequest(url: url)
        let retryConfig = RetryConfig(maxRetries: 3, initialBackoff: 0.1, retryNetworkErrors: false, retry500Errors: true, maxJitter: 0.1)

        _ = dispatcher.dispatchWithRetry(request: request, retryConfig: retryConfig) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertEqual((self.session.response as? HTTPURLResponse)?.statusCode, 500)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testNoRetryOnSuccess() throws {
        let expectation = self.expectation(description: "No retry on success")

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2", headerFields: nil)
        session.data = "Test".data(using: .utf8)

        let request = URLRequest(url: url)
        let retryConfig = RetryConfig(maxRetries: 3, initialBackoff: 0.1, retryNetworkErrors: true, retry500Errors: true, maxJitter: 0.1)

        _ = dispatcher.dispatchWithRetry(request: request, retryConfig: retryConfig) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.metadata.statusCode, 200)
                XCTAssertEqual(response.data, self.session.data)
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }

        waitForExpectations(timeout: 2.0)
    }
}
