//
//  NetworkService.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

typealias ResponseCompletion<T> = (Result<T, Error>) -> Void
typealias ResponseCompletionWithHeaders<T> = (Result<T, Error>, [String: String]?) -> Void

internal protocol NetworkService {
    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResponseCompletion<T>) -> PrimerCancellable?
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T

    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResponseCompletionWithHeaders<T>) -> PrimerCancellable?
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> (T, [String: String]?)

    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint, retryConfig: RetryConfig?, completion: @escaping ResponseCompletionWithHeaders<T>) -> PrimerCancellable?
    func request<T: Decodable>(_ endpoint: Endpoint, retryConfig: RetryConfig?) async throws -> (T, [String: String]?)
}
