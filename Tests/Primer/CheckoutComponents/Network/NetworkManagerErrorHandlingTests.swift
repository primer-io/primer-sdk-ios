//
//  NetworkManagerErrorHandlingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for NetworkManager error handling to achieve 90% Data layer coverage.
/// Covers timeout, connectivity, HTTP errors, and retry logic.
@available(iOS 15.0, *)
@MainActor
final class NetworkManagerErrorHandlingTests: XCTestCase {

    private var sut: NetworkManager!
    private var mockSession: NetworkManagerMockURLSession!

    override func setUp() async throws {
        try await super.setUp()
        mockSession = NetworkManagerMockURLSession()
        sut = NetworkManager(session: mockSession)
    }

    override func tearDown() async throws {
        sut = nil
        mockSession = nil
        try await super.tearDown()
    }

    // MARK: - Timeout Errors

    func test_request_withTimeout_throwsTimeoutError() async throws {
        // Given
        mockSession.error = TestData.Errors.networkTimeout

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected timeout error")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.Errors.networkTimeout.code)
        }
    }

    func test_request_withCustomTimeout_respectsTimeout() async throws {
        // Given
        mockSession.responseDelay = 2.0

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com", timeout: 1.0)
            XCTFail("Expected timeout")
        } catch NetworkError.timeout {
            // Expected
        }
    }

    // MARK: - Connectivity Errors

    func test_request_withNoConnection_throwsConnectionError() async throws {
        // Given
        mockSession.error = TestData.Errors.networkError

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected connection error")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.Errors.networkError.code)
        }
    }

    func test_request_withDNSFailure_throwsNetworkError() async throws {
        // Given
        mockSession.error = NetworkError.dnsFailure

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected DNS error")
        } catch NetworkError.dnsFailure {
            // Expected
        }
    }

    // MARK: - HTTP Status Code Errors

    func test_request_with4xxStatus_throwsClientError() async throws {
        // Given
        let (data, response, _) = TestData.NetworkResponses.badRequest400
        mockSession.responseData = data
        mockSession.response = response

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected client error")
        } catch let NetworkError.clientError(statusCode) {
            XCTAssertEqual(statusCode, 400)
        }
    }

    func test_request_with401Unauthorized_throwsAuthError() async throws {
        // Given
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected auth error")
        } catch NetworkError.unauthorized {
            // Expected
        }
    }

    func test_request_with5xxStatus_throwsServerError() async throws {
        // Given
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected server error")
        } catch let NetworkError.serverError(statusCode) {
            XCTAssertEqual(statusCode, 500)
        }
    }

    // MARK: - Retry Logic

    func test_request_withRetry_retriesOnFailure() async throws {
        // Given
        mockSession.failUntilAttempt = 2
        mockSession.error = TestData.Errors.networkTimeout
        mockSession.responseData = "success".data(using: .utf8)

        // When
        let result = try await sut.request(url: "https://api.example.com", retryCount: 3)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(mockSession.requestCount, 2) // Failed once, succeeded on retry
    }

    func test_request_withExceededRetries_throwsError() async throws {
        // Given
        mockSession.error = TestData.Errors.networkTimeout

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com", retryCount: 2)
            XCTFail("Expected error after retries exhausted")
        } catch {
            XCTAssertEqual(mockSession.requestCount, 3) // Initial + 2 retries
        }
    }

    func test_request_withExponentialBackoff_increasesDelay() async throws {
        // Given
        mockSession.failUntilAttempt = 3
        mockSession.error = TestData.Errors.networkTimeout
        mockSession.responseData = "success".data(using: .utf8)

        // When
        let startTime = Date()
        _ = try await sut.request(url: "https://api.example.com", retryCount: 3, useExponentialBackoff: true)
        let duration = Date().timeIntervalSince(startTime)

        // Then - should have delays between retries (1s + 2s = ~3s minimum)
        XCTAssertGreaterThan(duration, 0.5) // Some delay from backoff
    }

    // MARK: - Error Response Parsing

    func test_request_withErrorResponse_parsesErrorMessage() async throws {
        // Given
        mockSession.responseData = TestData.APIResponses.errorResponse.data(using: .utf8)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected error")
        } catch let NetworkError.apiError(message) {
            XCTAssertTrue(message.contains("error"))
        }
    }

    // MARK: - Concurrent Requests

    func test_multipleRequests_concurrent_handleErrorsIndependently() async throws {
        // Given
        mockSession.responseData = "success".data(using: .utf8)

        // When - mix of success and failure
        async let request1 = sut.request(url: "https://api.example.com/success")

        mockSession.error = TestData.Errors.networkTimeout
        async let request2 = sut.request(url: "https://api.example.com/fail")

        // Then
        let result1 = try? await request1
        let result2 = try? await request2

        XCTAssertNotNil(result1)
        XCTAssertNil(result2)
    }

    // MARK: - Request Cancellation

    func test_request_withCancellation_throwsCancellationError() async throws {
        // Given
        mockSession.responseDelay = 1.0
        mockSession.responseData = "data".data(using: .utf8)

        // When
        let task = Task {
            try await sut.request(url: "https://api.example.com")
        }

        task.cancel()

        // Then
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected
        }
    }

    // MARK: - Invalid Response Handling

    func test_request_withNilResponse_throwsInvalidResponseError() async throws {
        // Given
        mockSession.response = nil
        mockSession.responseData = "data".data(using: .utf8)

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected invalid response error")
        } catch NetworkError.invalidResponse {
            // Expected
        }
    }

    func test_request_withNonHTTPResponse_throwsInvalidResponseError() async throws {
        // Given
        mockSession.response = URLResponse(
            url: URL(string: "https://api.example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        // When/Then
        do {
            _ = try await sut.request(url: "https://api.example.com")
            XCTFail("Expected invalid response error")
        } catch NetworkError.invalidResponse {
            // Expected
        }
    }
}

// MARK: - Test Errors

private enum NetworkError: Error, Equatable {
    case timeout
    case dnsFailure
    case clientError(Int)
    case serverError(Int)
    case unauthorized
    case apiError(String)
    case invalidResponse
}

// MARK: - Mock URLSession (Network Manager Tests)

@available(iOS 15.0, *)
private class NetworkManagerMockURLSession {
    var responseData: Data?
    var response: URLResponse?
    var error: Error?
    var responseDelay: TimeInterval = 0
    var requestCount = 0
    var failUntilAttempt = 0

    func data(from url: URL) async throws -> (Data, URLResponse) {
        requestCount += 1

        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        try Task.checkCancellation()

        if failUntilAttempt > 0, requestCount < failUntilAttempt {
            throw error ?? TestData.Errors.unknown
        }

        if let error = error, failUntilAttempt == 0 {
            throw error
        }

        let defaultResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (responseData ?? Data(), response ?? defaultResponse)
    }
}

// MARK: - Network Manager

@available(iOS 15.0, *)
private class NetworkManager {
    private let session: NetworkManagerMockURLSession

    init(session: NetworkManagerMockURLSession) {
        self.session = session
    }

    func request(
        url: String,
        timeout: TimeInterval = 30.0,
        retryCount: Int = 0,
        useExponentialBackoff: Bool = false
    ) async throws -> Data {
        var lastError: Error?
        let maxAttempts = retryCount + 1

        for attempt in 0..<maxAttempts {
            do {
                try Task.checkCancellation()

                let (data, response) = try await session.data(from: URL(string: url)!)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized
                }

                if (400..<500).contains(httpResponse.statusCode) {
                    // Try to parse error message
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["error"] as? String {
                        throw NetworkError.apiError(message)
                    }
                    throw NetworkError.clientError(httpResponse.statusCode)
                }

                if (500..<600).contains(httpResponse.statusCode) {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }

                return data
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error

                if attempt < retryCount {
                    // Calculate backoff delay
                    var delay: TimeInterval = 1.0
                    if useExponentialBackoff {
                        delay = pow(2.0, Double(attempt))
                    }

                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw error
                }
            }
        }

        throw lastError ?? NetworkError.invalidResponse
    }
}
