//
//  RequestDispatcher.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerNetworking

extension DefaultRequestDispatcher: @retroactive RequestDispatcher, @retroactive LogReporter {

    @discardableResult
    public func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {
        let startTime = DispatchTime.now()
        let task = urlSession.dataTask(with: request) { data, urlResponse, error in
            let endTime = DispatchTime.now()
            let requestDuration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 // Convert to milliseconds

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                return completion(.failure(InternalError.missingHTTPResponse(underlyingError: error)))
            }

            let metadata = ResponseMetadataModel(
                responseUrl: httpResponse.responseUrl,
                statusCode: httpResponse.statusCode,
                headers: httpResponse.headers
            )
            let responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: requestDuration, data: data, error: error)
            completion(.success(responseModel))
        }

        task.resume()

        return task
    }

    @discardableResult
    public func dispatchWithRetry(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {
        retryHandler = RetryHandler(request: request, retryConfig: retryConfig, completion: completion, urlSession: urlSession)
        retryHandler?.attempt()
        return retryHandler?.currentTask
    }
}
