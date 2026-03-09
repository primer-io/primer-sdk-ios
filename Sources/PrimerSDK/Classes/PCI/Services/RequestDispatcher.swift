//
//  RequestDispatcher.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

typealias DispatcherCompletion = (Result<DispatcherResponse, Error>) -> Void

protocol RequestDispatcher: Sendable {
    func dispatch(request: URLRequest) async throws -> DispatcherResponse
    func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) -> PrimerCancellable?
    func dispatchWithRetry(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion) -> PrimerCancellable?
}

struct DispatcherResponseModel: DispatcherResponse {
    let metadata: ResponseMetadata
    let requestDuration: TimeInterval
    let data: Data?
    let error: Error?
}

struct ResponseMetadataModel: ResponseMetadata {
    let responseUrl: String?
    let statusCode: Int
    let headers: [String: String]?
}

protocol DispatcherResponse {
    var metadata: ResponseMetadata { get }
    var requestDuration: TimeInterval { get }
    var data: Data? { get }
    var error: Error? { get }
}

protocol URLSessionProtocol: Sendable {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}

final class DefaultRequestDispatcher: RequestDispatcher, LogReporter {

    let urlSession: URLSessionProtocol
    
    private var retryHandler: RetryHandler?

    init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }

    func dispatch(request: URLRequest) async throws -> DispatcherResponse {
        try await withCheckedThrowingContinuation { continuation in
            dispatch(request: request) { response in
                continuation.resume(with: response)
            }
        }
    }

    @discardableResult
    func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {
        let startTime = DispatchTime.now()
        let task = urlSession.dataTask(with: request) { data, urlResponse, error in
            let endTime = DispatchTime.now()
            let requestDuration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 // Convert to milliseconds

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                return completion(.failure(InternalError.missingHTTPResponse(underlyingError: error)))
            }

            let metadata = ResponseMetadataModel(responseUrl: httpResponse.responseUrl,
                                                 statusCode: httpResponse.statusCode,
                                                 headers: httpResponse.headers)
            let responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: requestDuration, data: data, error: error)
            completion(.success(responseModel))
        }

        task.resume()

        return task
    }

    @discardableResult
    func dispatchWithRetry(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {
        retryHandler = RetryHandler(request: request, retryConfig: retryConfig, completion: completion, urlSession: urlSession)
        retryHandler?.attempt()
        return retryHandler?.currentTask
    }
}

extension Task: PrimerCancellable {}
