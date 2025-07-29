//
//  CurrencyNetworkServiceProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable large_tuple

import Foundation

public protocol CurrencyNetworkServiceProtocol {
    func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

public final class CurrencyNetworkService: CurrencyNetworkServiceProtocol {
    public func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, response, error)
            }
        }
        task.resume()
    }
}

final class MockCurrencyNetworkService: CurrencyNetworkServiceProtocol {
    var mockResponse: (Data?, URLResponse?, Error?)?

    func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completion(mockResponse?.0, mockResponse?.1, mockResponse?.2)
    }
}
// swiftlint:enable large_tuple
