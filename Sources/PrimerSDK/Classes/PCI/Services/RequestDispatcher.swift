//
//  RequestDispatcher.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 14/03/2024.
//

import Foundation

typealias DispatcherCompletion = (DispatcherResponse) throws -> Void

protocol RequestDispatcher {
    func dispatch(request: URLRequest) async throws -> DispatcherResponse
    func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) throws -> PrimerCancellable?
}

struct DispatcherResponseModel: DispatcherResponse {
    let metadata: ResponseMetadata?
    let data: Data?
    let error: Error?
}

struct ResponseMetadataModel: ResponseMetadata {
    let responseUrl: String?
    let statusCode: Int
    let headers: [String: String]?
}

protocol DispatcherResponse {
    var metadata: ResponseMetadata? { get }
    var data: Data? { get }
    var error: Error? { get }
}

class DefaultRequestDispatcher: RequestDispatcher {

    let urlSession: URLSession

    let reportingService: NetworkReportingService

    init(urlSession: URLSession = .shared,
         reportingService: NetworkReportingService){
        self.urlSession = urlSession
        self.reportingService = reportingService
    }

    func dispatch(request: URLRequest) async throws -> DispatcherResponse {
        return try await withCheckedThrowingContinuation { continuation in
            urlSession.dataTask(with: request) { data, urlResponse, error in
                guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    // TODO: error
                    let error = InternalError.serverError(status: 0, response: nil, userInfo: nil, diagnosticsId: nil)
                    continuation.resume(throwing: error)
                    return
                }
                let metadata = ResponseMetadataModel(responseUrl: httpResponse.responseUrl,
                                                     statusCode: httpResponse.statusCode,
                                                     headers: httpResponse.headers)
                let responseModel = DispatcherResponseModel(metadata: metadata, data: data, error: error)
                continuation.resume(returning: responseModel)
            }
            .resume()
        }
    }

    func dispatch(request: URLRequest, completion: @escaping (DispatcherResponse) throws -> Void) throws -> PrimerCancellable? {
        Task {
            let response = try await dispatch(request: request)
            try completion(response)
        }
        return nil // TODO
    }
}
