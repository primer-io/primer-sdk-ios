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

class DefaultRequestDispatcher: RequestDispatcher, LogReporter {

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

        class RetryHandler: LogReporter {
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

            func logRetry(retryReason: String, backoffTime: TimeInterval) {
                self.logger.debug(message: "Retry attempt \(self.retries)/\(self.retryConfig.maxRetries) due to: \(retryReason). Waiting for \(backoffTime)s before next attempt.")
            }

            func handleRetry(responseModel: DispatcherResponseModel, error: Error?) {
                if self.shouldRetry(response: responseModel, error: error) {
                    self.retries += 1
                    let backoffTime = self.calculateBackoffWithJitter(baseDelay: self.retryConfig.initialBackoff,
                                                                      retryCount: self.retries,
                                                                      maxJitter: self.retryConfig.maxJitter)

                    let retryReason = error?.isNetworkError == true ? "Network error" : "HTTP \(responseModel.metadata.statusCode) error)"
                    self.logRetry(retryReason: retryReason, backoffTime: backoffTime)

                    DispatchQueue.global().asyncAfter(deadline: .now() + backoffTime) {
                        self.attempt()
                    }
                } else {
                    self.handleFinalFailure(responseModel: responseModel, error: error)
                }
            }

            func handleFinalFailure(responseModel: DispatcherResponseModel, error: Error?) {
                if self.retries >= self.retryConfig.maxRetries {
                    let errorMessage = "Failed after \(self.retries) retries. Reached maximum retries (\(self.retryConfig.maxRetries)). Last error object: \(error?.localizedDescription ?? "nil")"
                    self.logger.debug(message: errorMessage)
                    self.completion(.failure(PrimerError.missingPrimerConfiguration(userInfo: .errorUserInfoDictionary(),
                                                                                    diagnosticsId: UUID().uuidString)))
                } else if responseModel.metadata.statusCode >= 500 {
                    let errorMessage = "Failed after \(self.retries) retries from server error: \(responseModel.metadata.statusCode)"
                    self.logger.debug(message: errorMessage)
                    self.completion(.failure(PrimerError.missingPrimerConfiguration(userInfo: .errorUserInfoDictionary(),
                                                                                    diagnosticsId: UUID().uuidString)))
                } else {
                    self.completion(.failure(PrimerError.missingPrimerConfiguration(userInfo: .errorUserInfoDictionary(),
                                                                                    diagnosticsId: UUID().uuidString)))
                }
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

                    // Check if the response is successful
                    if (200...299).contains(responseModel.metadata.statusCode) {
                        self.completion(.success(responseModel))
                    } else {
                        self.handleRetry(responseModel: responseModel, error: error)
                    }
                }

                currentTask?.resume()
            }

            func shouldRetry(response: DispatcherResponse, error: Error?) -> Bool {
                let isLastAttempt = retries >= retryConfig.maxRetries
                let isNetworkError = error != nil && error?.isNetworkError == true
                let is500Error = response.metadata.statusCode >= 500
                let isSomeOtherError = !isNetworkError && !is500Error

                if isLastAttempt || isNetworkError || is500Error || isSomeOtherError {
                    var finalErrorMessage = ""
                    if isLastAttempt {
                        finalErrorMessage += "Reached maximum retries (\(retryConfig.maxRetries))."
                    } else if isNetworkError {
                        finalErrorMessage += "Network error encountered and RetryConfig.retryNetworkErrors is \(retryConfig.retryNetworkErrors ? "enabled" : "disabled")."
                    } else if is500Error {
                        finalErrorMessage += "HTTP \(response.metadata.statusCode) error encountered and RetryConfig.retry500Errors is \(retryConfig.retry500Errors ? "enabled" : "disabled")."
                    } else if isSomeOtherError {
                        finalErrorMessage += "HTTP \(response.metadata.statusCode) error encountered."
                    }

                    finalErrorMessage += " Last error: \(error?.localizedDescription ?? "Unknown error")"
                    self.logger.debug(message: finalErrorMessage)
                }

                let shouldRetry = !isLastAttempt && ((isNetworkError && retryConfig.retryNetworkErrors) ||
                                          (is500Error && retryConfig.retry500Errors) ||
                                          isSomeOtherError)
                return shouldRetry
            }
        }

        let retryHandler = RetryHandler(request: request, retryConfig: retryConfig, completion: completion, urlSession: urlSession)
        retryHandler.attempt()
        return retryHandler.currentTask
    }
}

extension Task: PrimerCancellable {}
