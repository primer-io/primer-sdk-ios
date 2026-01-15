//
//  PollingModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

protocol Module {

    // swiftlint:disable:next type_name
    associatedtype T

    static var apiClient: PrimerAPIClientProtocol? { get set }

    init(url: URL)

    func start() async throws -> T
    func cancel(withError err: PrimerError)
}

final class PollingModule: Module {

    static var apiClient: PrimerAPIClientProtocol?

    let url: URL
    var retryInterval: TimeInterval = 3
    private(set) var cancellationError: PrimerError?
    private(set) var failureError: PrimerError?

    required init(url: URL) {
        self.url = url
    }

    func start() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.startPolling { id, err in
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

    private func startPolling(completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        if let cancellationError {
            completion(nil, cancellationError)
            return
        }

        if let failureError {
            completion(nil, failureError)
            return
        }

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        let apiClient: PrimerAPIClientProtocol = PollingModule.apiClient ?? PrimerAPIClient()

        apiClient.poll(clientToken: decodedJWTToken, url: self.url.absoluteString) { result in
            switch result {
            case let .success(res):
                if res.status == .pending {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.startPolling(completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.unknown(message: "Received unexpected polling status for id '\(res.id)'")
                    ErrorHandler.handle(error: err)
                }
            case let .failure(err):
                ErrorHandler.handle(error: err)
                // Retry
                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryInterval) {
                    self.startPolling(completion: completion)
                }
            }
        }
    }
}
