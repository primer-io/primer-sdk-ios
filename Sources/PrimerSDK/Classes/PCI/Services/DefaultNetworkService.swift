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

    func request<T>(_ endpoint: any Endpoint, 
                    completion: @escaping ResponseCompletionWithHeaders<T>) -> (any PrimerCancellable)? where T: Decodable {
        do {
            let request = try requestFactory.request(for: endpoint)

            reportingService.report(eventType: .networkConnectivity(endpoint: endpoint))

            let identifier = String.randomString(length: 32)
            reportingService.report(eventType: .requestStart(identifier: identifier,
                                                             endpoint: endpoint,
                                                             request: request))

            let startTime = DispatchTime.now()

            return try requestDispatcher.dispatch(request: request) { [reportingService] result in
                let endTime = DispatchTime.now()
                let timeElapsed = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 // Convert to milliseconds

                let response: DispatcherResponse
                switch result {
                case .success(let theResponse):
                    response = theResponse
                case .failure(let error):
                    completion(.failure(error), nil)
                    return
                }

                reportingService.report(eventType: .requestEnd(identifier: identifier,
                                                               endpoint: endpoint,
                                                               response: response.metadata,
                                                               duration: timeElapsed))

                if let error = response.error {
                    completion(.failure(InternalError.underlyingErrors(errors: [error],
                                                                       userInfo: .errorUserInfoDictionary(),
                                                                       diagnosticsId: UUID().uuidString)), nil)
                    return
                }

                self.logger.debug(message: response.metadata.description)
                guard let data = response.data else {
                    completion(.failure(InternalError.noData(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)), nil)
                    return
                }

                do {
                    let responseHeaders = response.metadata.headers
                    let response: T = try endpoint.responseFactory.model(for: data, forMetadata: response.metadata)
                    completion(.success(response), responseHeaders)
                } catch {
                    completion(.failure(error), nil)
                }

            }
        } catch {
            ErrorHandler.handle(error: error)
            completion(.failure(error), nil)
            return nil
        }
    }

    func request<T>(_ endpoint: Endpoint, completion: @escaping ResponseCompletion<T>) -> PrimerCancellable? where T: Decodable {
        request(endpoint) { result, _ in
            completion(result)
        }
    }
}
