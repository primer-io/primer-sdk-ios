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

class DefaultRequestDispatcher: RequestDispatcher {

    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
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
}

extension Task: PrimerCancellable {}
