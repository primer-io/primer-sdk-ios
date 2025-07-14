//
//  PrimerInternalError.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

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
        case let .failedToDecode(_, _, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case let .invalidUrl(_, _, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case let .invalidValue(_, _, _, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case let .invalidResponse(_, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case let .noData(_, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case let .serverError(_, _, _, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case let .unauthorized(_, _, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case let .underlyingErrors(_, _, diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToPerform3dsButShouldContinue,
             .failedToPerform3dsAndShouldBreak,
             .noNeedToPerform3ds:
            return UUID().uuidString
        }
    }

    var errorDescription: String? {
        switch self {
        case let .failedToDecode(message, _, _):
            return "[\(errorId)] Failed to decode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(diagnosticsId))"
        case let .invalidUrl(url, _, _):
            return "[\(errorId)] Invalid URL \(url ?? "nil") (diagnosticsId: \(diagnosticsId))"
        case let .invalidValue(key, value, _, _):
            return "[\(errorId)] Invalid value \(value ?? "nil") for key \(key) (diagnosticsId: \(diagnosticsId))"
        case .invalidResponse:
            return "[\(errorId)] Invalid response received. Expected HTTP response. (diagnosticsId: \(diagnosticsId)"
        case .noData:
            return "[\(errorId)] No data"
        case let .serverError(status, response, _, _):
            var resStr = "nil"
            if let response = response,
               let resData = try? JSONEncoder().encode(response),
               let str = resData.prettyPrintedJSONString as String?
            {
                resStr = str
            }
            return "[\(errorId)] Server error [\(status)] Response: \(resStr) (diagnosticsId: \(diagnosticsId))"
        case let .unauthorized(url, _, _):
            return "[\(errorId)] Unauthorized response for URL \(url) (diagnosticsId: \(diagnosticsId))"
        case let .underlyingErrors(errors, _, _):
            return "[\(errorId)] Multiple errors occured | Errors \(errors.combinedDescription) (diagnosticsId: \(diagnosticsId))"
        case .failedToPerform3dsButShouldContinue:
            return "[\(errorId)] Failed to perform 3DS but should continue"
        case let .failedToPerform3dsAndShouldBreak(error):
            return "[\(errorId)] Failed to perform 3DS with error \(error.localizedDescription), and should break"
        case let .noNeedToPerform3ds(status):
            return "[\(errorId)] No need to perform 3DS because status is \(status)"
        }
    }

    var info: [String: Any]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]

        switch self {
        case let .failedToDecode(_, userInfo, _),
             let .invalidUrl(_, userInfo, _),
             let .invalidValue(_, _, userInfo, _),
             let .invalidResponse(userInfo, _),
             let .noData(userInfo, _),
             let .serverError(_, _, userInfo, _),
             let .unauthorized(_, userInfo, _),
             let .underlyingErrors(_, userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { _, new in new }
            tmpUserInfo["diagnosticsId"] = diagnosticsId
        case .failedToPerform3dsButShouldContinue,
             .failedToPerform3dsAndShouldBreak,
             .noNeedToPerform3ds:
            break
        }

        return tmpUserInfo
    }

    var errorUserInfo: [String: Any] {
        return info ?? [:]
    }

    var exposedError: Error {
        switch self {
        case let .failedToPerform3dsButShouldContinue(error):
            return error.primerError
        case let .failedToPerform3dsAndShouldBreak(error):
            return error.primerError
        default:
            return PrimerError.unknown(userInfo: errorUserInfo as? [String: String], diagnosticsId: diagnosticsId)
        }
    }

    var analyticsContext: [String: Any] {
        var context: [String: Any] = [:]
        context[AnalyticsContextKeys.errorId] = errorId
        return context
    }
}
