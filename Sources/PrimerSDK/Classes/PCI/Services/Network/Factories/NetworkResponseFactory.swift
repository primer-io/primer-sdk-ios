//
//  NetworkResponseFactory.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation

protocol NetworkResponseFactory: AnyObject {
    func model<T>(for response: Data, forMetadata metadata: ResponseMetadata) throws -> T where T: Decodable
}

extension Endpoint {
    var responseFactory: NetworkResponseFactory {
        if let endpoint = self as? PrimerAPI {
            switch endpoint {
            case .redirect:
                return SuccessResponseFactory()
            default:
                break
            }
        }
        return JSONNetworkResponseFactory()
    }
}

final class SuccessResponseFactory: NetworkResponseFactory {
    func model<T>(for response: Data, forMetadata metadata: any ResponseMetadata) throws -> T where T: Decodable {
        if let response = SuccessResponse() as? T {
            return response
        }
        throw InternalError.failedToDecode(message: "SuccessResponse model must be used with this endpoint")
    }
}

final class JSONNetworkResponseFactory: NetworkResponseFactory, LogReporter {

    let decoder = JSONDecoder()

    func model<T>(for response: Data, forMetadata metadata: ResponseMetadata) throws -> T where T: Decodable {
        log(data: response, metadata: metadata)

        switch metadata.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: response)
            } catch {
                // Attempt to decode a server error response even if the status code is 2xx.
                // Some APIs return error messages in the response body while still using a success status code.
                // To handle this, we try decoding the response as `PrimerServerErrorResponse` first.
                if let serverError = try? decoder.decode(PrimerServerErrorResponse.self, from: response) {
                    throw InternalError.serverError(
                        status: metadata.statusCode,
                        response: serverError.error,
                        diagnosticsId: serverError.error.diagnosticsId
                    )
                } else {
                    throw InternalError.failedToDecode(
                        message: "Failed to decode response of type '\(T.self)' from URL: \(metadata.responseUrl ?? "Unknown")"
                    )
                }
            }
        case 401:
            throw InternalError.unauthorized(url: metadata.responseUrl ?? "Unknown")
        case 400, 402...599:
            let serverError = try? decoder.decode(PrimerServerErrorResponse.self, from: response)
            throw InternalError.serverError(status: metadata.statusCode, response: serverError?.error)
        default:
            throw InternalError.failedToDecode(
                message: "Failed to determine response from URL: \(metadata.responseUrl ?? "Unknown")"
            )
        }
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
