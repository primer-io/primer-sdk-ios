//
//  NetworkService.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 17/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class MockNetworkService: NetworkService {

    func request<T>(_ endpoint: any PrimerSDK.Endpoint, completion: @escaping PrimerSDK.ResponseCompletionWithHeaders<T>) -> (any PrimerSDK.PrimerCancellable)? where T : Decodable {
        onReceiveEndpoint?(endpoint)

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let error = self.mockedError {
                completion(.failure(error), nil)
            } else if let result = self.mockedResult as? T {
                completion(.success(result), [:])
            } else {
                XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            }
        }

        return nil
    }
    

    var mockedResult: Decodable?

    var mockedError: Error?

    let mockedNetworkDelay: TimeInterval = Double.random(in: 0...2)

    var onReceiveEndpoint: ((Endpoint) -> Void)?

    func request<T>(_ endpoint: PrimerSDK.Endpoint,
                    completion: @escaping PrimerSDK.ResponseCompletion<T>) -> PrimerCancellable? where T: Decodable {

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

    func request<T>(_ endpoint: any PrimerSDK.Endpoint, retryConfig: PrimerSDK.RetryConfig?, completion: @escaping PrimerSDK.ResponseCompletionWithHeaders<T>) -> (any PrimerSDK.PrimerCancellable)? where T : Decodable {
        onReceiveEndpoint?(endpoint)

        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let error = self.mockedError {
                completion(.failure(error), nil)
            } else if let result = self.mockedResult as? T {
                completion(.success(result), nil)
            } else {
                XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            }
        }

        return nil
    }
}
