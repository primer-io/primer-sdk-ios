//
//  RequestDispatcher.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 14/03/2024.
//

import Foundation

protocol RequestDispatcher {
    func dispatch(request: URLRequest) async throws -> DispatcherResponse
    func dispatch(request: URLRequest, completion: (DispatcherResponse) throws -> Void) throws -> PrimerCancellable?
}

struct DispatcherResponseModel: DispatcherResponse {
    let metadata: ResponseMetadata?
    let data: Data?
    let error: Error?
}

struct ResponseMetadataModel: ResponseMetadata {
    let responseUrl: String?
    let statusCode: Int
    let headers: [String : String]?
}

class DefaultRequestDispatcher: RequestDispatcher {

    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func dispatch(request: URLRequest) async throws -> DispatcherResponse {
        let (response, data) = await urlSession.data(for: request)
        let metadata = ResponseMetadataModel(responseUrl: response., statusCode: <#T##Int#>, headers: <#T##[String : String]?#>)
        return DispatcherResponseModel(metadata: <#T##ResponseMetadata?#>
    }

    func dispatch(request: URLRequest, completion: (DispatcherResponse) throws -> Void) throws -> PrimerCancellable? {
        return nil
    }
}
