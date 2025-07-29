//
//  NetworkServiceProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

typealias ResponseCompletion<T> = (Result<T, Error>) -> Void
typealias ResponseCompletionWithHeaders<T> = (Result<T, Error>, [String: String]?) -> Void

internal protocol NetworkServiceProtocol {
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
