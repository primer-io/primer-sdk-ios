//
//  NetworkService.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

typealias ResponseCompletion<T> = (Result<T, Error>) -> Void

internal protocol NetworkService {
    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResponseCompletion<T>) -> PrimerCancellable?
}
