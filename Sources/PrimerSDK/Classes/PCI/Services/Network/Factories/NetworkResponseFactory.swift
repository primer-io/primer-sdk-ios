//
//  NetworkResponseFactory.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 14/03/2024.
//

import Foundation

protocol NetworkResponseFactory: AnyObject {
    func model<T>(for response: Data) throws -> T where T: Decodable
}

extension Endpoint {
    var responseFactory: NetworkResponseFactory {
        switch self {
        default:
            return JSONNetworkResponseFactory()
        }
    }
}

class JSONNetworkResponseFactory: NetworkResponseFactory {

    let decoder = JSONDecoder()

    func model<T>(for response: Data) throws -> T where T: Decodable {
        do {
            return try decoder.decode(T.self, from: response)
        } catch {
            throw InternalError.failedToDecode(message: nil, userInfo: nil, diagnosticsId: nil)
        }
    }
}
