//
//  PrimerInternalError.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum InternalError: PrimerErrorProtocol {
    case failedToDecode(message: String?, diagnosticsId: String = .uuid)
    case invalidUrl(url: String?, diagnosticsId: String = .uuid)
    case invalidValue(key: String, value: Any? = nil, diagnosticsId: String = .uuid)
    case invalidResponse(diagnosticsId: String = .uuid)
    case noData(diagnosticsId: String = .uuid)
    case serverError(status: Int, response: PrimerServerError? = nil, diagnosticsId: String = .uuid)
    case unauthorized(url: String, diagnosticsId: String = .uuid)
    case underlyingErrors(errors: [Error], diagnosticsId: String = .uuid)
    case failedToPerform3dsButShouldContinue(error: Primer3DSErrorContainer)
    case failedToPerform3dsAndShouldBreak(error: Error)
    case noNeedToPerform3ds(status: String)

    var errorId: String {
        switch self {
        case .failedToDecode: "failed-to-decode"
        case .invalidUrl: "invalid-url"
        case .invalidValue: "invalid-value"
        case .invalidResponse: "invalid-response"
        case .noData: "no-data"
        case .serverError: "server-error"
        case .unauthorized: "unauthorized"
        case .underlyingErrors: "underlying-errors"
        case .failedToPerform3dsButShouldContinue: "failed-to-perform-3ds-but-should-continue"
        case .failedToPerform3dsAndShouldBreak: "failed-to-perform-3ds-and-should-break"
        case .noNeedToPerform3ds: "no-need-to-perform-3ds"
        }
    }

    var diagnosticsId: String {
        switch self {
        case .failedToDecode(_, let diagnosticsId),
                .invalidUrl(_, let diagnosticsId),
                .invalidValue(_, _, let diagnosticsId),
                .invalidResponse(let diagnosticsId),
                .noData(let diagnosticsId),
                .serverError(_, _, let diagnosticsId),
                .unauthorized(_, let diagnosticsId),
                .underlyingErrors(_, let diagnosticsId):
            diagnosticsId
        case .failedToPerform3dsButShouldContinue,
                .failedToPerform3dsAndShouldBreak,
                .noNeedToPerform3ds:
            UUID().uuidString
        }
    }

    var errorDescription: String? {
        switch self {
        case .failedToDecode(let message, _):
            return "[\(errorId)] Failed to decode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .invalidUrl(let url, _):
            return "[\(errorId)] Invalid URL \(url ?? "nil") (diagnosticsId: \(self.diagnosticsId))"
        case .invalidValue(let key, let value, _):
            return "[\(errorId)] Invalid value \(value ?? "nil") for key \(key) (diagnosticsId: \(self.diagnosticsId))"
        case .invalidResponse:
            return "[\(errorId)] Invalid response received. Expected HTTP response. (diagnosticsId: \(self.diagnosticsId)"
        case .noData:
            return "[\(errorId)] No data"
        case .serverError(let status, let response, _):
            var resStr: String = "nil"
            if let response = response,
               let resData = try? JSONEncoder().encode(response),
               let str = resData.prettyPrintedJSONString as String? {
                resStr = str
            }
            return "[\(errorId)] Server error [\(status)] Response: \(resStr) (diagnosticsId: \(self.diagnosticsId))"
        case .unauthorized(let url, _):
            return "[\(errorId)] Unauthorized response for URL \(url) (diagnosticsId: \(self.diagnosticsId))"
        case .underlyingErrors(let errors, _):
            return "[\(errorId)] Multiple errors occured | Errors \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId))"
        case .failedToPerform3dsButShouldContinue:
            return "[\(errorId)] Failed to perform 3DS but should continue"
        case .failedToPerform3dsAndShouldBreak(let error):
            return "[\(errorId)] Failed to perform 3DS with error \(error.localizedDescription), and should break"
        case .noNeedToPerform3ds(let status):
            return "[\(errorId)] No need to perform 3DS because status is \(status)"
        }
    }

    var exposedError: Error {
        switch self {
        case .failedToPerform3dsButShouldContinue(let error): error.primerError
        case .failedToPerform3dsAndShouldBreak(let error): error.primerError
        default: PrimerError.unknown(diagnosticsId: self.diagnosticsId)
        }
    }

    var analyticsContext: [String: Any] { [AnalyticsContextKeys.errorId: errorId] }
}
