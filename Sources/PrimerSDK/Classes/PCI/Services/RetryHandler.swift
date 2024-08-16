//
//  RetryHandler.swift
//  PrimerSDK
//
//  Created by Boris on 25.7.24..
//

import Foundation

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
        return exponentialPart + jitterPart
    }

    func handleRetry(responseModel: DispatcherResponseModel, error: Error?) {
        if self.shouldRetry(response: responseModel, error: error) {
            self.retries += 1
            let backoffTime = self.calculateBackoffWithJitter(baseDelay: self.retryConfig.initialBackoff,
                                                              retryCount: self.retries,
                                                              maxJitter: self.retryConfig.maxJitter)

            let retryReason = error?.isNetworkError == true ? "Network error" : "HTTP \(responseModel.metadata.statusCode) error)"
            let message = "Retry attempt \(self.retries)/\(self.retryConfig.maxRetries) due to: \(retryReason). Waiting for \(backoffTime)s before next attempt."
            self.logger.debug(message: message)

            let retryEvent = Analytics.Event.message(message: message, messageType: .retry, severity: .warning)
            Analytics.Service.record(event: retryEvent)

            DispatchQueue.global().asyncAfter(deadline: .now() + backoffTime) {
                self.attempt()
            }
        } else {
            self.handleFinalFailure(responseModel: responseModel, error: error)
        }
    }

    func handleFinalFailure(responseModel: DispatcherResponseModel, error: Error?) {
        var errorMessage = "Failed after \(self.retries) retries.\n"

        if self.retries >= self.retryConfig.maxRetries {
            errorMessage += "Reached maximum retries (\(self.retryConfig.maxRetries)).\nLast error object: \(error?.localizedDescription ?? "nil")"
        } else if responseModel.metadata.statusCode >= 500 {
            errorMessage += "Server error: \(responseModel.metadata.statusCode)"
        } else if let error = error {
            errorMessage += "Last error object: \(error.localizedDescription)"
        } else {
            errorMessage += "Status code: \(responseModel.metadata.statusCode)"
        }
        self.logger.debug(message: errorMessage)
        let retryEvent = Analytics.Event.message(message: errorMessage, messageType: .retryFailed, severity: .error)
        Analytics.Service.record(event: retryEvent)

        self.completion(.failure(PrimerError.missingPrimerConfiguration(userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)))
    }

    func attempt() {
        let startTime = DispatchTime.now()
        currentTask = urlSession.dataTask(with: request) { data, urlResponse, error in

            let endTime = DispatchTime.now()
            let requestDuration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 // Convert to milliseconds

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                let error = InternalError.invalidResponse(userInfo: .errorUserInfoDictionary(),
                                                          diagnosticsId: UUID().uuidString)
                self.completion(.failure(error))
                return
            }

            let metadata = ResponseMetadataModel(responseUrl: httpResponse.url?.absoluteString,
                                                 statusCode: httpResponse.statusCode,
                                                 headers: httpResponse.allHeaderFields as? [String: String])
            let responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: requestDuration, data: data, error: error)

            // Check if the response is successful
            if (200...299).contains(responseModel.metadata.statusCode) {
                let successMessage = "Request succeeded after \(self.retries) retries. Status code: \(responseModel.metadata.statusCode)"
                self.logger.debug(message: successMessage)
                let retryEvent = Analytics.Event.message(message: successMessage, messageType: .retrySuccess, severity: .info)
                Analytics.Service.record(event: retryEvent)
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

            finalErrorMessage += "Last error: \(error?.localizedDescription ?? "Unknown error")"
            let retryEvent = Analytics.Event.message(message: finalErrorMessage, messageType: .retry, severity: .warning)
            Analytics.Service.record(event: retryEvent)
            self.logger.debug(message: finalErrorMessage)
        }

        let shouldRetry = !isLastAttempt && ((isNetworkError && retryConfig.retryNetworkErrors) ||
                                  (is500Error && retryConfig.retry500Errors) ||
                                  isSomeOtherError)
        return shouldRetry
    }
}
