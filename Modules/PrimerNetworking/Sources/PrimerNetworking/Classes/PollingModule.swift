//
//  PollingModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

protocol Module {

    // swiftlint:disable:next type_name
    associatedtype T

    init(url: URL, pollable: Pollable, token: DecodedJWTToken?)

    func start(retryConfig: RetryConfig?) async throws -> T
    func cancel(withError err: PrimerError)
}

@_spi(PrimerInternal) public protocol Pollable {
    func poll(clientToken: DecodedJWTToken?, url: String, retryConfig: RetryConfig?, completion: @escaping APICompletion<PollingResponse>)
}

@_spi(PrimerInternal) public final class PollingModule: Module {
    
    static var apiClient: Pollable?
    
    private let pollable: Pollable

    private(set) var cancellationError: PrimerError?
    private(set) var failureError: PrimerError?
    
    private let url: URL
    private let token: DecodedJWTToken?
    private var retryInterval: TimeInterval = 3

    public init(url: URL, pollable: Pollable, token: DecodedJWTToken?) {
        self.url = url
        self.pollable = pollable
        self.token = token
    }

    public func start(retryConfig: RetryConfig? = nil) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.startPolling(retryConfig: retryConfig) { id, err in
                if let err {
                    continuation.resume(throwing: err)
                } else if let id {
                    continuation.resume(returning: id)
                } else {
                    precondition(false, "Should always return an id or an error")
                }
            }
        }
    }

    public func cancel(withError err: PrimerError) {
        self.cancellationError = err
    }

    public func fail(withError err: PrimerError) {
        self.failureError = err
    }

    private func startPolling(
        retryConfig: RetryConfig? = nil,
        completion: @escaping (_ id: String?, _ err: Error?) -> Void
    ) {
        if let cancellationError {
            return completion(nil, cancellationError)
        }

        if let failureError {
            return completion(nil, failureError)
        }

        guard let token else {
            let err = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: err)
            return completion(nil, err)
        }

        let pollable = Self.apiClient ?? pollable
        
        pollable.poll(clientToken: token, url: self.url.absoluteString, retryConfig: retryConfig) { result in
            switch result {
            case let .success(res):
                if res.status == .pending {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.startPolling(retryConfig: retryConfig, completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.unknown(message: "Received unexpected polling status for id '\(res.id)'")
                    ErrorHandler.handle(error: err)
                    completion(nil, err)
                }
            case let .failure(err):
                ErrorHandler.handle(error: err)
                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryInterval) {
                    self.startPolling(retryConfig: retryConfig, completion: completion)
                }
            }
        }
    }
}
