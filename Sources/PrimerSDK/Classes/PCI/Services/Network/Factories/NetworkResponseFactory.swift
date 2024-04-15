//
//  NetworkResponseFactory.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 14/03/2024.
//

import Foundation

protocol NetworkResponseFactory: AnyObject {
    func model<T>(for response: Data, forMetadata metadata: ResponseMetadata) throws -> T where T: Decodable
}

extension Endpoint {
    var responseFactory: NetworkResponseFactory {
        switch self {
        default:
            return JSONNetworkResponseFactory()
        }
    }
}

class JSONNetworkResponseFactory: NetworkResponseFactory, LogReporter {

    let decoder = JSONDecoder()

    func model<T>(for response: Data, forMetadata metadata: ResponseMetadata) throws -> T where T: Decodable {

        log(data: response, metadata: metadata)

        switch metadata.statusCode {
        case 200:
            do {
                return try decoder.decode(T.self, from: response)
            } catch {
                throw InternalError.failedToDecode(message: "Failed to decode response of type '\(T.self)' from URL: \(metadata.responseUrl ?? "Unknown")",
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
            }
        case 400...599:
            let serverError = try? decoder.decode(PrimerServerErrorResponse.self, from: response)
            throw InternalError.serverError(status: metadata.statusCode,
                                            response: serverError?.error,
                                            userInfo: .errorUserInfoDictionary(),
                                            diagnosticsId: UUID().uuidString)
        default:
            break
        }

        throw InternalError.failedToDecode(message: "Failed to determine response from URL: \(metadata.responseUrl ?? "Unknown")",
                                           userInfo: .errorUserInfoDictionary(),
                                           diagnosticsId: UUID().uuidString)

    }

    func log(data: Data, metadata: ResponseMetadata) {
        let url = metadata.responseUrl ?? "Unknown URL"
        let headersDescription = metadata.headers?.map { (key, value) in
            "  ► \(key): \(value)"
        } ?? ["No headers found"]
        let body = String(data: data, encoding: .utf8) ?? "N/A"

        logger.debug(message: """

🌎 [Response] 👉 \(url)
Headers:
\(headersDescription.joined(separator: "\n"))
Body:
\(body)
""")
    }
}
