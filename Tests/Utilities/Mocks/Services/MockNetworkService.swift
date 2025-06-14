//
//  MockNetworkService.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 17/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

@testable import PrimerSDK
import XCTest

class MockNetworkService: NetworkService {
    var mockedResult: Decodable?
    var mockedError: Error?
    var mockedHeaders: [String: String]?
    let mockedNetworkDelay: TimeInterval = Double.random(in: 0 ... 2)
    var onReceiveEndpoint: ((Endpoint) -> Void)?

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
