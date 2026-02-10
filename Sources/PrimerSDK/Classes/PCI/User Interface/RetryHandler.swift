//
//  RetryHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation
import PrimerNetworking

extension RetryHandler: @retroactive LogReporter {
    
    func attempt() {
        let startTime = DispatchTime.now()
        currentTask = urlSession.dataTask(with: request) { [weak self] data, urlResponse, error in
            guard let self else { return }
            guard let httpResponse = urlResponse as? HTTPURLResponse else { return handleNoResponseReceived(error: error) }
            
            let requestDuration = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            let statusCode = httpResponse.statusCode
            
            let metadata = ResponseMetadataModel(responseUrl: httpResponse.url?.absoluteString, statusCode: statusCode, headers: httpResponse.headers)
            let responseModel = DispatcherResponseModel(metadata: metadata, requestDuration: requestDuration, data: data, error: error)
            
            if (200...299).contains(statusCode) {
                handleSuccessfulResponseReceived(model: responseModel)
            } else {
                attemptRetry(statusCode: statusCode, error: error)
            }
        }
        currentTask?.resume()
    }
    
    private func handleSuccessfulResponseReceived(model: DispatcherResponseModel) {
        let successMessage = "Request succeeded after \(retries) retries. Status code: \(model.metadata.statusCode)"
        logger.debug(message: successMessage)
        if retries > 0 {
            Analytics.Service.fire(event: .message(message: successMessage, messageType: .retrySuccess, severity: .info))
        }
        completion(.success(model))
    }

    private func handleNoResponseReceived(error: Error?) {
        if let error, retryConfig.retryNetworkErrors, error.isNetworkError {
            attemptRetry(statusCode: error.nsErrorCode, error: error)
        } else {
            completion(.failure(InternalError.invalidResponse()))
        }
    }

    private func attemptRetry(statusCode: Int, error: Error?) {
        if shouldRetry(statusCode: statusCode, error: error) {
            retry(statusCode: statusCode, error: error)
        } else {
            handleFinalFailure(statusCode: statusCode, error: error)
        }
    }
    
    private func retry(statusCode: Int, error: Error?) {
        retries += 1
        let retryReason = error?.isNetworkError == true ? "Network error" : "HTTP \(statusCode) error"
        let attemptCount = "\(retries)/\(retryConfig.maxRetries)"
        let backoff = backoffWithJitter
        let message = "Retry attempt \(attemptCount) due to: \(retryReason). \(backoff)s before next attempt."
        logger.debug(message: message)
        Analytics.Service.fire(event: .message(message: message, messageType: .retry, severity: .warning))
        DispatchQueue.global().asyncAfter(deadline: .now() + backoff) { self.attempt() }
    }
    
    private func shouldRetry(statusCode: Int, error: Error?) -> Bool {
        let isLastAttempt = retries >= retryConfig.maxRetries
        let isNetworkError = error?.isNetworkError == true
        let is500Error = statusCode.isServerErrorCode
        let isSomeOtherError = !isNetworkError && !is500Error
        
        let lastAttemptMessage = "Reached maximum retries (\(retryConfig.maxRetries))."
        let networkErrorMessage = "Network error encountered and retryNetworkErrors is \(retryConfig.retryNetworkErrors)."
        let received500ErrorMessage = "HTTP \(statusCode) error encountered and RetryConfig.retry500Errors is \(retryConfig.retry500Errors)."
    
        var message = ""
        if isLastAttempt {
            message += lastAttemptMessage
        } else if isNetworkError {
            message += networkErrorMessage
        } else if is500Error {
            message += received500ErrorMessage
        } else if isSomeOtherError {
            message += "HTTP \(statusCode) error encountered."
        }
        
        message += "\nLast error: \(error?.localizedDescription ?? "Unknown error")"
        Analytics.Service.fire(event: .message(message: message, messageType: .retry, severity: .warning))
        logger.warn(message: message)
        
        guard !isLastAttempt else { return false }
        let shouldRetryNetworkError = isNetworkError && retryConfig.retryNetworkErrors
        let shouldRetry500Error = is500Error && retryConfig.retry500Errors
        return shouldRetry500Error || shouldRetryNetworkError || isSomeOtherError
    }

    private func handleFinalFailure(statusCode: Int, error: Error?) {
        var errorMessage = "Failed after \(retries) retries.\n"
        if retries >= retryConfig.maxRetries {
            errorMessage += "Reached maximum retries (\(retryConfig.maxRetries))."
        } else {
            errorMessage += "\(statusCode.isServerErrorCode ? "Server error" : "Status") code: \(statusCode)"
        }
        
        if let error {
            errorMessage += "\nLast error object: \(error.localizedDescription)"
        }
        
        logger.error(message: errorMessage)
        Analytics.Service.fire(event: .message(message: errorMessage, messageType: .retryFailed, severity: .error))
        completion(.failure(InternalError.networkFailedAfterRetries(lastError: error)))
    }
}

private extension Int {
    var isServerErrorCode: Bool { 500..<600 ~= self }
}
