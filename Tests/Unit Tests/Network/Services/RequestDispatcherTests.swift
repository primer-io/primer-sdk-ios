//
//  RequestDispatcherTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 08/04/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

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
        _ = try dispatcher.dispatch(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.metadata.responseUrl, "https://a_url")
                XCTAssertEqual(response.metadata.statusCode, 200)
                XCTAssertEqual(response.data, self.session.data)
                expectation.fulfill()
            case .failure(_):
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
        _ = try dispatcher.dispatch(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.metadata.responseUrl, "https://a_url")
                XCTAssertEqual(response.metadata.statusCode, 500)
                XCTAssertEqual(response.data, self.session.data)
                expectation.fulfill()
            case .failure(_):
                XCTFail()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testFailedDispatchResponse_sync() throws {
        let expectation = self.expectation(description: "Successful response received")

        let urlString = "https://a_url"
        let url = URL(string: urlString)!

        session.error = PrimerError.unknown(userInfo: nil, diagnosticsId: "")

        let request = URLRequest(url: url)
        _ = try dispatcher.dispatch(request: request) { result in
            switch result {
            case .success(_):
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

        session.error = PrimerError.unknown(userInfo: nil, diagnosticsId: "")

        let request = URLRequest(url: url)
        do {
            _ = try await dispatcher.dispatch(request: request)
        } catch {
            XCTAssertTrue(error.localizedDescription.hasPrefix("[invalid-response] Invalid response received. Expected HTTP response."))
        }
    }

}
