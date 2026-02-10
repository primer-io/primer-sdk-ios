//
//  RequestDispatcher.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation
import PrimerNetworking

extension DefaultRequestDispatcher: @retroactive RequestDispatcher, @retroactive LogReporter {

    @discardableResult
    public func dispatchWithRetry(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {
        retryHandler = RetryHandler(request: request, retryConfig: retryConfig, completion: completion, urlSession: urlSession)
        retryHandler?.attempt()
        return retryHandler?.currentTask
    }
}
