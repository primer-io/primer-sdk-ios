//
//  RequestDispatcher.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public typealias DispatcherCompletion = (Result<DispatcherResponse, Error>) -> Void

public protocol RequestDispatcher: Sendable {
    func dispatch(request: URLRequest) async throws -> DispatcherResponse
    func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) -> PrimerCancellable?
    func dispatchWithRetry(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion) -> PrimerCancellable?
}

public struct DispatcherResponseModel: DispatcherResponse {
    public let metadata: ResponseMetadata
    public let requestDuration: TimeInterval
    public let data: Data?
    public let error: Error?
    
    public init(
        metadata: ResponseMetadata,
        requestDuration: TimeInterval,
        data: Data?,
        error: Error?
    ) {
        self.metadata = metadata
        self.requestDuration = requestDuration
        self.data = data
        self.error = error
    }
}

public struct ResponseMetadataModel: ResponseMetadata {
    public let responseUrl: String?
    public let statusCode: Int
    public let headers: [String: String]?
    
    public init(responseUrl: String?, statusCode: Int, headers: [String : String]?) {
        self.responseUrl = responseUrl
        self.statusCode = statusCode
        self.headers = headers
    }
}

public protocol DispatcherResponse {
    var metadata: ResponseMetadata { get }
    var requestDuration: TimeInterval { get }
    var data: Data? { get }
    var error: Error? { get }
}

public protocol URLSessionProtocol: Sendable {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}

public final class DefaultRequestDispatcher: Sendable {

    public let urlSession: URLSessionProtocol

    public init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }
}

extension Task: PrimerCancellable {}
