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
        return url?.absoluteString
    }

    var headers: [String : String]? {
        return allHeaderFields.reduce(into: [:]) { result, item in
            if let key = item.key as? String, let value = item.value as? String {
                result[key] = value
            }
        }
    }
}

// --

enum NetworkEventType {
    case requestStart
    case requestEnd
    case networkCall
}

protocol NetworkReportingService {
    func report(eventType: NetworkEventType)
}

class DefaultNetworkReportingService: NetworkReportingService {
    func report(eventType: NetworkEventType) {
        // ... 
    }
}

// --

class DefaultNetworkService: NetworkService, LogReporter {

    let requestFactory: NetworkRequestFactory

    let reportingService: NetworkReportingService

    let requestDispatcher: RequestDispatcher

    init(requestFactory: NetworkRequestFactory,
         reportingService: NetworkReportingService,
         requestDispatcher: RequestDispatcher) {
        self.requestFactory = requestFactory
        self.reportingService = reportingService
        self.requestDispatcher = requestDispatcher
    }

    func request<T>(_ endpoint: Endpoint, completion: @escaping ResponseCompletion<T>) -> PrimerCancellable? where T: Decodable {

        do {
            let request = try requestFactory.request(for: endpoint)
            return try requestDispatcher.dispatch(request: request) { response in
                guard let metadata = response.metadata else {
                    // TODO: new error - noResponse
                    completion(.failure(InternalError.noData(userInfo: nil, diagnosticsId: nil)))
                    return
                }
                self.logger.debug(message: metadata.description)
                guard let data = response.data else {
                    // TODO: add context to error
                    completion(.failure(InternalError.noData(userInfo: nil, diagnosticsId: nil)))
                    return
                }
                let response: T = try endpoint.responseFactory.model(for: data)
                completion(.success(response))
            }
        } catch {
            completion(.failure(error))
        }

        // TODO: log / error

        return nil
    }
}
