//
//  PrimerInternalError.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum InternalError: PrimerErrorProtocol {
    case failedToDecode(
        message: String?,
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidUrl(
        url: String?,
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidValue(
        key: String,
        value: Any? = nil,
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidResponse(
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case noData(
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case serverError(
        status: Int,
        response: PrimerServerError? = nil,
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case unauthorized(
        url: String,
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case underlyingErrors(
        errors: [Error],
        userInfo: [String: String] = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case failedToPerform3dsButShouldContinue(error: Primer3DSErrorContainer)
    case failedToPerform3dsAndShouldBreak(error: Error)
    case noNeedToPerform3ds(status: String)

    var errorId: String {
        switch self {
        case .failedToDecode:
            return "failed-to-decode"
        case .invalidUrl:
            return "invalid-url"
        case .invalidValue:
            return "invalid-value"
        case .invalidResponse:
            return "invalid-response"
        case .noData:
            return "no-data"
        case .serverError:
            return "server-error"
        case .unauthorized:
            return "unauthorized"
        case .underlyingErrors:
            return "underlying-errors"
        case .failedToPerform3dsButShouldContinue:
            return "failed-to-perform-3ds-but-should-continue"
        case .failedToPerform3dsAndShouldBreak:
            return "failed-to-perform-3ds-and-should-break"
        case .noNeedToPerform3ds:
            return "no-need-to-perform-3ds"
        }
    }

    var diagnosticsId: String {
        switch self {
        case .failedToDecode(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidUrl(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidValue(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidResponse(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .noData(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .serverError(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .unauthorized(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .underlyingErrors(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToPerform3dsButShouldContinue,
             .failedToPerform3dsAndShouldBreak,
             .noNeedToPerform3ds:
            return UUID().uuidString
        }
    }

    var errorDescription: String? {
        switch self {
        case .failedToDecode(let message, _, _):
            return "[\(errorId)] Failed to decode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .invalidUrl(let url, _, _):
            return "[\(errorId)] Invalid URL \(url ?? "nil") (diagnosticsId: \(self.diagnosticsId))"
        case .invalidValue(let key, let value, _, _):
            return "[\(errorId)] Invalid value \(value ?? "nil") for key \(key) (diagnosticsId: \(self.diagnosticsId))"
        case .invalidResponse:
            return "[\(errorId)] Invalid response received. Expected HTTP response. (diagnosticsId: \(self.diagnosticsId)"
        case .noData:
            return "[\(errorId)] No data"
        case .serverError(let status, let response, _, _):
            var resStr: String = "nil"
            if let response = response,
               let resData = try? JSONEncoder().encode(response),
               let str = resData.prettyPrintedJSONString as String? {
                resStr = str
            }
            return "[\(errorId)] Server error [\(status)] Response: \(resStr) (diagnosticsId: \(self.diagnosticsId))"
        case .unauthorized(let url, _, _):
            return "[\(errorId)] Unauthorized response for URL \(url) (diagnosticsId: \(self.diagnosticsId))"
        case .underlyingErrors(let errors, _, _):
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
        case .failedToPerform3dsButShouldContinue(let error):
            return error.primerError
        case .failedToPerform3dsAndShouldBreak(let error):
            return error.primerError
        default:
            return PrimerError.unknown(userInfo: self.errorUserInfo as? [String: String], diagnosticsId: self.diagnosticsId)
        }
    }

    var analyticsContext: [String: Any] {
        var context: [String: Any] = [:]
        context[AnalyticsContextKeys.errorId] = errorId
        return context
    }
}
