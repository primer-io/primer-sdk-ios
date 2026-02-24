//
//  PollingModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol Module {

    // swiftlint:disable:next type_name
    associatedtype T

    static var apiClient: PrimerAPIClientProtocol? { get set }

    init(url: URL)

    func start(retryConfig: RetryConfig?) async throws -> T
    func cancel(withError err: PrimerError)
}

final class PollingModule: Module {

    static var apiClient: PrimerAPIClientProtocol?

    private(set) var cancellationError: PrimerError?
    private(set) var failureError: PrimerError?
    
    private let url: URL
    private var retryInterval: TimeInterval = 3

    init(url: URL) {
        self.url = url
    }

    func start(retryConfig: RetryConfig? = nil) async throws -> String {
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

    func cancel(withError err: PrimerError) {
        self.cancellationError = err
    }

    func fail(withError err: PrimerError) {
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

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: err)
            return completion(nil, err)
        }

        let apiClient: PrimerAPIClientProtocol = PollingModule.apiClient ?? PrimerAPIClient()

        apiClient.poll(clientToken: decodedJWTToken, url: self.url.absoluteString, retryConfig: retryConfig) { result in
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
