//
//  DefaultNetworkService.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 07/03/2024.
//

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

class DefaultNetworkService: NetworkService, LogReporter {

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
        return request(endpoint, retryConfig: nil, completion: completion)
    }

    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint,
                               retryConfig: RetryConfig?,
                               completion: @escaping ResponseCompletion<T>) -> PrimerCancellable? {
        do {
            let request = try requestFactory.request(for: endpoint)

            reportingService.report(eventType: .networkConnectivity(endpoint: endpoint))

            let identifier = String.randomString(length: 32)
            reportingService.report(eventType: .requestStart(identifier: identifier,
                                                             endpoint: endpoint,
                                                             request: request))

            let dispatchFunction = createDispatchFunction(retryConfig: retryConfig)

            return dispatchFunction(request) { [weak self] result in
                self?.handleDispatchResult(result, identifier: identifier,
                                           endpoint: endpoint,
                                           completion: completion)
            }
        } catch {
            ErrorHandler.handle(error: error)
            completion(.failure(error))
            return nil
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

    private func handleSuccess<T: Decodable>(response: DispatcherResponse,
                                             identifier: String,
                                             endpoint: Endpoint,
                                             completion: @escaping ResponseCompletion<T>) {
        reportingService.report(eventType: .requestEnd(identifier: identifier,
                                                       endpoint: endpoint,
                                                       response: response.metadata,
                                                       duration: response.requestDuration))

        if let error = response.error {
            completion(.failure(InternalError.underlyingErrors(errors: [error],
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)))
            return
        }

        self.logger.debug(message: response.metadata.description)
        guard let data = response.data else {
            completion(.failure(InternalError.noData(userInfo: .errorUserInfoDictionary(), diagnosticsId: UUID().uuidString)))
            return
        }

        do {
            let response: T = try endpoint.responseFactory.model(for: data, forMetadata: response.metadata)
            completion(.success(response))
        } catch {
            completion(.failure(error))
        }
    }
}
