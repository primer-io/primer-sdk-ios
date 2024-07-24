//
//  RequestDispatcher.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 14/03/2024.
//

import Foundation

typealias DispatcherCompletion = (Result<DispatcherResponse, Error>) -> Void

protocol RequestDispatcher {
    func dispatch(request: URLRequest) async throws -> DispatcherResponse
    func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) throws -> PrimerCancellable?
    func dispatchWithRetry(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion) -> PrimerCancellable?
}

struct DispatcherResponseModel: DispatcherResponse {
    let metadata: ResponseMetadata
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
    var data: Data? { get }
    var error: Error? { get }
}

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}

class DefaultRequestDispatcher: RequestDispatcher {

    let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }

    func dispatch(request: URLRequest) async throws -> DispatcherResponse {
        return try await withCheckedThrowingContinuation { continuation in
            dispatch(request: request) { response in
                continuation.resume(with: response)
            }
        }
    }

    @discardableResult
    func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {
        let task = urlSession.dataTask(with: request) { data, urlResponse, error in
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                let error = InternalError.invalidResponse(userInfo: .errorUserInfoDictionary(),
                                                          diagnosticsId: UUID().uuidString)
                completion(.failure(error))
                return
            }

            let metadata = ResponseMetadataModel(responseUrl: httpResponse.responseUrl,
                                                 statusCode: httpResponse.statusCode,
                                                 headers: httpResponse.headers)
            let responseModel = DispatcherResponseModel(metadata: metadata, data: data, error: error)
            completion(.success(responseModel))
        }

        task.resume()

        return task
    }

    @discardableResult
    func dispatchWithRetry(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {

        class RetryHandler {
            let request: URLRequest
            let retryConfig: RetryConfig
            let completion: DispatcherCompletion
            let urlSession: URLSessionProtocol

            var retries = 0
            var currentTask: URLSessionDataTask?

            init(request: URLRequest, retryConfig: RetryConfig, completion: @escaping DispatcherCompletion, urlSession: URLSessionProtocol) {
                self.request = request
                self.retryConfig = retryConfig
                self.completion = completion
                self.urlSession = urlSession
            }

            func calculateBackoffWithJitter(baseDelay: TimeInterval, retryCount: Int, maxJitter: TimeInterval) -> TimeInterval {
                let exponentialPart = baseDelay * pow(2.0, Double(retryCount - 1))
                let jitterPart = Double.random(in: 0...maxJitter)
                return min(exponentialPart + jitterPart, Double.greatestFiniteMagnitude)
            }

            func attempt() {
                currentTask = urlSession.dataTask(with: request) { data, urlResponse, error in
                    guard let httpResponse = urlResponse as? HTTPURLResponse else {
                        let error = InternalError.invalidResponse(userInfo: .errorUserInfoDictionary(),
                                                                  diagnosticsId: UUID().uuidString)
                        self.completion(.failure(error))
                        return
                    }

                    let metadata = ResponseMetadataModel(responseUrl: httpResponse.url?.absoluteString,
                                                         statusCode: httpResponse.statusCode,
                                                         headers: httpResponse.allHeaderFields as? [String: String])
                    let responseModel = DispatcherResponseModel(metadata: metadata, data: data, error: error)

                    if (responseModel.metadata.statusCode >= 500 || error != nil) && self.retries < self.retryConfig.maxRetries {
                        self.retries += 1
                        let backoffTime = self.calculateBackoffWithJitter(baseDelay: self.retryConfig.initialBackoff,
                                                                          retryCount: self.retries,
                                                                          maxJitter: self.retryConfig.maxJitter)
                        DispatchQueue.global().asyncAfter(deadline: .now() + backoffTime) {
                            self.attempt()
                        }
                    } else {
                        self.completion(.success(responseModel))
                    }
                }

                currentTask?.resume()
            }
        }

        let retryHandler = RetryHandler(request: request, retryConfig: retryConfig, completion: completion, urlSession: urlSession)
        retryHandler.attempt()
        return retryHandler.currentTask
    }
}

extension Task: PrimerCancellable {}
