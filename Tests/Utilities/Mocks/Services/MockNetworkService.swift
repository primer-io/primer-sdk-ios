//
//  MockNetworkService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class MockNetworkService: NetworkServiceProtocol {
    var mockedResult: Decodable?
    var mockedError: Error?
    var mockedHeaders: [String: String]?
    var onReceiveEndpoint: ((Endpoint) -> Void)?
    private let mockedNetworkDelay: TimeInterval = Double.random(in: 0 ... 1)

    func request<T>(
        _ endpoint: PrimerSDK.Endpoint,
        completion: @escaping PrimerSDK.ResponseCompletion<T>
    ) -> PrimerCancellable? where T: Decodable {
        onReceiveEndpoint?(endpoint)

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let error = self.mockedError {
                completion(.failure(error))
            } else if let result = self.mockedResult as? T {
                completion(.success(result))
            } else {
                XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            }
        }

        return nil
    }

    func request<T>(
        _ endpoint: any Endpoint
    ) async throws -> T where T: Decodable {
        onReceiveEndpoint?(endpoint)
        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let error = mockedError {
            throw error
        } else if let result = mockedResult as? T {
            return result
        } else {
            XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            throw NSError(domain: "MockNetworkService", code: -1, userInfo: nil)
        }
    }

    func request<T>(
        _ endpoint: any PrimerSDK.Endpoint,
        completion: @escaping PrimerSDK.ResponseCompletionWithHeaders<T>
    ) -> (any PrimerSDK.PrimerCancellable)? where T: Decodable {
        onReceiveEndpoint?(endpoint)

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let error = self.mockedError {
                completion(.failure(error), nil)
            } else if let result = self.mockedResult as? T {
                completion(.success(result), self.mockedHeaders)
            } else {
                XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            }
        }

        return nil
    }

    func request<T>(_ endpoint: any Endpoint) async throws -> (T, [String: String]?) where T: Decodable {
        onReceiveEndpoint?(endpoint)
        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let error = mockedError {
            throw error
        } else if let result = mockedResult as? T {
            return (result, self.mockedHeaders)
        } else {
            XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            throw NSError(domain: "MockNetworkService", code: -1, userInfo: nil)
        }
    }

    func request<T>(
        _ endpoint: any PrimerSDK.Endpoint,
        retryConfig _: PrimerSDK.RetryConfig?,
        completion: @escaping PrimerSDK.ResponseCompletionWithHeaders<T>
    ) -> (any PrimerSDK.PrimerCancellable)? where T: Decodable {
        onReceiveEndpoint?(endpoint)

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let error = self.mockedError {
                completion(.failure(error), nil)
            } else if let result = self.mockedResult as? T {
                completion(.success(result), self.mockedHeaders)
            } else {
                XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            }
        }

        return nil
    }

    func request<T>(
        _ endpoint: any Endpoint,
        retryConfig _: RetryConfig?
    ) async throws -> (T, [String: String]?) where T: Decodable {
        onReceiveEndpoint?(endpoint)
        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        if let error = mockedError {
            throw error
        } else if let result = mockedResult as? T {
            return (result, self.mockedHeaders)
        } else {
            XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            throw NSError(domain: "MockNetworkService", code: -1, userInfo: nil)
        }
    }
}
