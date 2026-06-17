//
//  CurrencyNetworkServiceProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable large_tuple

import Foundation

public protocol CurrencyNetworkServiceProtocol {
    func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

public final class CurrencyNetworkService: CurrencyNetworkServiceProtocol {
    @_spi(PrimerInternal) public init() {}
    
    public func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, response, error)
            }
        }
        task.resume()
    }
}
// swiftlint:enable large_tuple
