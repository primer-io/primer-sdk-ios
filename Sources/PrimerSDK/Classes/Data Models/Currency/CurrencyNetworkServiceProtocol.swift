//
//  CurrencyNetworkServiceProtocol.swift
//  PrimerSDK
//
//  Created by Boris on 24.1.24..
//

// swiftlint:disable large_tuple

import Foundation

public protocol CurrencyNetworkServiceProtocol {
    func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

public class CurrencyNetworkService: CurrencyNetworkServiceProtocol {
    public func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, response, error)
            }
        }
        task.resume()
    }
}

class MockCurrencyNetworkService: CurrencyNetworkServiceProtocol {
    var mockResponse: (Data?, URLResponse?, Error?)?

    func fetchData(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completion(mockResponse?.0, mockResponse?.1, mockResponse?.2)
    }
}
// swiftlint:enable large_tuple
