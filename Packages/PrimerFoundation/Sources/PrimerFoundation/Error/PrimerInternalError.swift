//
//  PrimerInternalError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation   

public enum InternalError {
    case failedToDecode(message: String?, diagnosticsId: String = .uuid)
    case invalidUrl(url: String?, diagnosticsId: String = .uuid)
    case invalidValue(key: String, value: Any? = nil, diagnosticsId: String = .uuid)
    case invalidResponse(diagnosticsId: String = .uuid)
    case noData(diagnosticsId: String = .uuid)
    case serverError(status: Int, response: PrimerServerError? = nil, diagnosticsId: String = .uuid)
    case unauthorized(url: String, diagnosticsId: String = .uuid)
    case underlyingErrors(errors: [Error], diagnosticsId: String = .uuid)
    case failedToPerform3dsButShouldContinue(error: Error)
    case failedToPerform3dsAndShouldBreak(error: Error)
    case noNeedToPerform3ds(status: String)

    public var errorId: String {
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

    public var diagnosticsId: String {
        switch self {
        case let .failedToDecode(_, diagnosticsId),
                let .invalidUrl(_, diagnosticsId),
                let .invalidValue(_, _, diagnosticsId),
                let .invalidResponse(diagnosticsId),
                let .noData(diagnosticsId),
                let .serverError(_, _, diagnosticsId),
                let .unauthorized(_, diagnosticsId),
                let .underlyingErrors(_, diagnosticsId):
            diagnosticsId
        case .failedToPerform3dsButShouldContinue,
                .failedToPerform3dsAndShouldBreak,
                .noNeedToPerform3ds:
            UUID().uuidString
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .failedToDecode(message, _):
            return "[\(errorId)] Failed to decode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case let .invalidUrl(url, _):
            return "[\(errorId)] Invalid URL \(url ?? "nil") (diagnosticsId: \(self.diagnosticsId))"
        case let .invalidValue(key, value, _):
            return "[\(errorId)] Invalid value \(value ?? "nil") for key \(key) (diagnosticsId: \(self.diagnosticsId))"
        case .invalidResponse:
            return "[\(errorId)] Invalid response received. Expected HTTP response. (diagnosticsId: \(self.diagnosticsId)"
        case .noData:
            return "[\(errorId)] No data"
        case let .serverError(status, response, _):
            var resStr: String = "nil"
            if let response = response,
               let resData = try? JSONEncoder().encode(response),
               let str = resData.prettyPrintedJSONString as String? {
                resStr = str
            }
            return "[\(errorId)] Server error [\(status)] Response: \(resStr) (diagnosticsId: \(self.diagnosticsId))"
        case let .unauthorized(url, _):
            return "[\(errorId)] Unauthorized response for URL \(url) (diagnosticsId: \(self.diagnosticsId))"
        case let .underlyingErrors(errors, _):
            return "[\(errorId)] Multiple errors occured | Errors \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId))"
        case .failedToPerform3dsButShouldContinue:
            return "[\(errorId)] Failed to perform 3DS but should continue"
        case let .failedToPerform3dsAndShouldBreak(error):
            return "[\(errorId)] Failed to perform 3DS with error \(error.localizedDescription), and should break"
        case let .noNeedToPerform3ds(status):
            return "[\(errorId)] No need to perform 3DS because status is \(status)"
        }
    }

    public var analyticsContext: [String: Any] { [AnalyticsContextKeys.errorId: errorId] }
}
