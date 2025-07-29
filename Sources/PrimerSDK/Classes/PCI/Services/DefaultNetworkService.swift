//
//  DefaultNetworkService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol ResponseMetadata {
    var responseUrl: String? { get }
    var statusCode: Int { get }
    var headers: [String: String]? { get }
}

extension ResponseMetadata {
    var description: String {
        "\(responseUrl ?? "Unknown URL") => \(statusCode)"
    }
}

extension HTTPURLResponse: ResponseMetadata {

    var responseUrl: String? {
        url?.absoluteString
    }

    var headers: [String: String]? {
        allHeaderFields.reduce(into: [:]) { result, item in
            if let key = item.key as? String, let value = item.value as? String {
                result[key] = value
            }
        }
    }
}

final class DefaultNetworkService: NetworkServiceProtocol, LogReporter {

    let requestFactory: NetworkRequestFactory
    let requestDispatcher: RequestDispatcher
    let reportingService: NetworkReportingService

    init(requestFactory: NetworkRequestFactory,
         requestDispatcher: RequestDispatcher,
         reportingService: NetworkReportingService) {
        self.requestFactory = requestFactory
        self.requestDispatcher = requestDispatcher
        self.reportingService = reportingService
    }

    init(withUrlSession urlSession: URLSession = .shared,
         analyticsService: Analytics.Service = .shared) {
        self.requestFactory = DefaultNetworkRequestFactory()
        self.requestDispatcher = DefaultRequestDispatcher(urlSession: urlSession)
        self.reportingService = DefaultNetworkReportingService(analyticsService: analyticsService)
    }

    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint,
                               completion: @escaping ResponseCompletion<T>) -> PrimerCancellable? {
        do {
            let identifier = String.randomString(length: 32)

            let request = try requestFactory.request(for: endpoint, identifier: identifier)

            reportingService.report(eventType: .networkConnectivity(endpoint: endpoint))

            reportingService.report(eventType: .requestStart(identifier: identifier,
                                                             endpoint: endpoint,
                                                             request: request))

            let dispatchFunction = createDispatchFunction(retryConfig: nil)

            return dispatchFunction(request) { [weak self] result in
                self?.handleDispatchResult(result, identifier: identifier, endpoint: endpoint, completion: completion)
            }
        } catch {
            completion(.failure(handled(error: error)))
            return nil
        }
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        try await awaitResult { completion in
            self.request(endpoint, completion: completion)
        }
    }

    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint,
                               completion: @escaping ResponseCompletionWithHeaders<T>) -> PrimerCancellable? {
        return request(endpoint, retryConfig: nil, completion: completion)
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> (T, [String: String]?) {
        try await awaitResult { completion in
            self.request(endpoint, completion: completion)
        }
    }

    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint,
                               retryConfig: RetryConfig?,
                               completion: @escaping ResponseCompletionWithHeaders<T>) -> PrimerCancellable? {
        do {
            let identifier = String.randomString(length: 32)
            let request = try requestFactory.request(for: endpoint, identifier: identifier)
            reportingService.report(eventType: .networkConnectivity(endpoint: endpoint))
            reportingService.report(eventType: .requestStart(identifier: identifier,
                                                             endpoint: endpoint,
                                                             request: request))

            let dispatchFunction = createDispatchFunction(retryConfig: retryConfig)

            return dispatchFunction(request) { [weak self] result in
                self?.handleDispatchResult(result, identifier: identifier, endpoint: endpoint, completion: completion)
            }
        } catch {
            completion(.failure(handled(error: error)), nil)
            return nil
        }
    }

    func request<T: Decodable>(_ endpoint: Endpoint, retryConfig: RetryConfig?) async throws -> (T, [String: String]?) {
        try await awaitResult { completion in
            self.request(endpoint, retryConfig: retryConfig, completion: completion)
        }
    }

    private func createDispatchFunction(retryConfig: RetryConfig?) -> (URLRequest, @escaping DispatcherCompletion) -> PrimerCancellable? {
        return { request, completion in
            if let retryConfig = retryConfig, retryConfig.enabled {
                return (self.requestDispatcher as? DefaultRequestDispatcher)?.dispatchWithRetry(request: request,
                                                                                                retryConfig: retryConfig,
                                                                                                completion: completion)
            } else {
                return self.requestDispatcher.dispatch(request: request, completion: completion)
            }
        }
    }

    private func handleDispatchResult<T: Decodable>(_ result: Result<DispatcherResponse, Error>,
                                                    identifier: String,
                                                    endpoint: Endpoint,
                                                    completion: @escaping ResponseCompletion<T>) {
        switch result {
        case .success(let response):
            handleSuccess(response: response, identifier: identifier, endpoint: endpoint, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }

    private func handleDispatchResult<T: Decodable>(_ result: Result<DispatcherResponse, Error>,
                                                    identifier: String,
                                                    endpoint: Endpoint,
                                                    completion: @escaping ResponseCompletionWithHeaders<T>) {
        switch result {
        case .success(let response):
            handleSuccess(response: response, identifier: identifier, endpoint: endpoint, completion: completion)
        case .failure(let error):
            completion(.failure(error), nil)
        }
    }

    private func handleSuccess<T: Decodable>(response: DispatcherResponse,
                                             identifier: String,
                                             endpoint: Endpoint,
                                             completion: @escaping ResponseCompletion<T>) {
        reportingService.report(eventType: .requestEnd(identifier: identifier,
                                                       endpoint: endpoint,
                                                       response: response.metadata,
                                                       duration: response.requestDuration))

        if let error = response.error {
            return completion(.failure(InternalError.underlyingErrors(errors: [error])))
        }

        self.logger.debug(message: response.metadata.description)
        guard let data = response.data else { return completion(.failure(InternalError.noData())) }

        do {
            let response: T = try endpoint.responseFactory.model(for: data, forMetadata: response.metadata)
            completion(.success(response))
        } catch {
            completion(.failure(error))
        }
    }

    private func handleSuccess<T: Decodable>(response: DispatcherResponse,
                                             identifier: String,
                                             endpoint: Endpoint,
                                             completion: @escaping ResponseCompletionWithHeaders<T>) {
        reportingService.report(eventType: .requestEnd(identifier: identifier,
                                                       endpoint: endpoint,
                                                       response: response.metadata,
                                                       duration: response.requestDuration))

        if let error = response.error {
            return completion(
                .failure(InternalError.underlyingErrors(errors: [error])),
                nil
            )
        }

        self.logger.debug(message: response.metadata.description)
        guard let data = response.data else { return completion(.failure(InternalError.noData()), nil) }

        do {
            let responseHeaders = response.metadata.headers
            let response: T = try endpoint.responseFactory.model(for: data, forMetadata: response.metadata)
            completion(.success(response), responseHeaders)
        } catch {
            completion(.failure(error), nil)
        }
    }
}
