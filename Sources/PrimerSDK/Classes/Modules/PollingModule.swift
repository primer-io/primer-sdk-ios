//
//  PollingModule.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol Module {

    // swiftlint:disable:next type_name
    associatedtype T

    static var apiClient: PrimerAPIClientProtocol? { get set }

    init(url: URL)

    func start() -> Promise<T>
    func start() async throws -> T
    func cancel(withError err: PrimerError)
}

final class PollingModule: Module {

    static var apiClient: PrimerAPIClientProtocol?

    internal let url: URL
    internal var retryInterval: TimeInterval = 3
    internal private(set) var cancellationError: PrimerError?
    internal private(set) var failureError: PrimerError?

    required init(url: URL) {
        self.url = url
    }

    func start() -> Promise<String> {
        return Promise { seal in
            self.startPolling { (resumeToken, err) in
                if let err = err {
                    seal.reject(err)
                } else if let resumeToken = resumeToken {
                    seal.fulfill(resumeToken)
                } else {
                    precondition(false, "Should always return an id or an error")
                }
            }
        }
    }

    func start() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
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
            let err = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        let apiClient: PrimerAPIClientProtocol = PollingModule.apiClient ?? PrimerAPIClient()

        apiClient.poll(clientToken: decodedJWTToken, url: self.url.absoluteString) { result in
            switch result {
            case .success(let res):
                if res.status == .pending {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.startPolling(completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.unknown(
                        userInfo: .errorUserInfoDictionary(additionalInfo: [
                            "message": "Received unexpected polling status for id '\(res.id)'"
                        ]),
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: err)
                }
            case .failure(let err):
                ErrorHandler.handle(error: err)
                // Retry
                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryInterval) {
                    self.startPolling(completion: completion)
                }
            }
        }
    }
}
