//
//  Service.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

typealias ResultCallback<T> = (Result<T, NetworkServiceError>) -> Void

protocol NetworkService {
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResultCallback<T>)
}
