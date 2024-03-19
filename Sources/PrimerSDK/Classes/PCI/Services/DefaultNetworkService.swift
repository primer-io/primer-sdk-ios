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

    var headers: [String: String]? {
        return allHeaderFields.reduce(into: [:]) { result, item in
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

    func request<T>(_ endpoint: Endpoint, completion: @escaping ResponseCompletion<T>) -> PrimerCancellable? where T: Decodable {

        do {
            let request = try requestFactory.request(for: endpoint)

            reportingService.report(eventType: .networkConnectivity)

            let identifier = String.randomString(length: 32)
            reportingService.report(eventType: .requestStart(identifier: identifier,
                                                             endpoint: endpoint,
                                                             request: request))

            return try requestDispatcher.dispatch(request: request) { [reportingService] response in
                reportingService.report(eventType: .requestEnd(identifier: identifier,
                                                               endpoint: endpoint,
                                                               response: response.metadata))

                self.logger.debug(message: response.metadata.description)
                guard let data = response.data else {
                    completion(.failure(InternalError.noData(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)))
                    return
                }

                let response: T = try endpoint.responseFactory.model(for: data, forUrl: request.url?.absoluteString)
                completion(.success(response))
            }
        } catch {
            ErrorHandler.handle(error: error)
            completion(.failure(error))
        }

        // TODO: log / error

        return nil
    }
}
