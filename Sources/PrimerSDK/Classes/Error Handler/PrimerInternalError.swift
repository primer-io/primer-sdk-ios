//
//  PrimerInternalError.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

import Foundation

internal enum InternalError: PrimerErrorProtocol {

    case failedToEncode(message: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case failedToDecode(message: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case failedToSerialize(message: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case connectivityErrors(errors: [Error], userInfo: [String: String]?, diagnosticsId: String?)
    case invalidUrl(url: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidValue(key: String, value: Any?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidResponse(userInfo: [String: String]?, diagnosticsId: String?)
    case noData(userInfo: [String: String]?, diagnosticsId: String?)
    case serverError(status: Int, response: PrimerServerError?, userInfo: [String: String]?, diagnosticsId: String?)
    case unauthorized(url: String, method: HTTPMethod, userInfo: [String: String]?, diagnosticsId: String?)
    case underlyingErrors(errors: [Error], userInfo: [String: String]?, diagnosticsId: String?)
    case failedToPerform3dsButShouldContinue(error: Primer3DSErrorContainer)
    case failedToPerform3dsAndShouldBreak(error: Error)
    case noNeedToPerform3ds(status: String)

    var errorId: String {
        switch self {
        case .failedToEncode:
            return "failed-to-encode"
        case .failedToDecode:
            return "failed-to-decode"
        case .failedToSerialize:
            return "failed-to-serialize"
        case .connectivityErrors:
            return "connectivity-errors"
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
        case .failedToEncode(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToDecode(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToSerialize(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .connectivityErrors(_, _, let diagnosticsId):
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
        case .unauthorized(_, _, _, let diagnosticsId):
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
        case .failedToEncode(let message, _, _):
            return "[\(errorId)] Failed to encode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .failedToDecode(let message, _, _):
            return "[\(errorId)] Failed to decode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .failedToSerialize(let message, _, _):
            return "[\(errorId)] Failed to serialize\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .connectivityErrors(let errors, _, _):
            return "[\(errorId)] Connectivity failure | Errors: \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId))"
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
        case .unauthorized(let url, let method, _, _):
            return "[\(errorId)] Unauthorized response for URL \(url) [\(method.rawValue)] (diagnosticsId: \(self.diagnosticsId))"
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

    var info: [String: Any]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]

        switch self {
        case .failedToEncode(_, let userInfo, _),
             .failedToDecode(_, let userInfo, _),
             .failedToSerialize(_, let userInfo, _),
             .connectivityErrors(_, let userInfo, _),
             .invalidUrl(_, let userInfo, _),
             .invalidValue(_, _, let userInfo, _),
             .invalidResponse(let userInfo, _),
             .noData(let userInfo, _),
             .serverError(_, _, let userInfo, _),
             .unauthorized(_, _, let userInfo, _),
             .underlyingErrors(_, let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            tmpUserInfo["diagnosticsId"] = self.diagnosticsId
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

    var recoverySuggestion: String? {
        switch self {
        case .failedToEncode:
            return "Check object's encode(to:) function for wrong CodingKeys, or unexpected values."
        case .failedToDecode:
            return "Check object's init(from:) function for wrong CodingKeys, or unexpected values."
        case .failedToSerialize:
            return "Check if all object's properties can be serialized."
        case .connectivityErrors:
            return "Check underlying conectivity errors for more information."
        case .invalidUrl:
            return "Provide a valid URL, meaning that it must include http(s):// at the begining and also follow URL formatting rules."
        case .invalidValue(let key, let value, _, _):
            return "Check if value \(value ?? "nil") is valid for key \(key)"
        case .noData:
            return "If you were expecting data on this response, check that your backend has sent the appropriate data."
        case .serverError, .invalidResponse:
            return "Check the server's response to debug this error further."
        case .unauthorized:
            return "Check that the you have provided the SDK with a client token."
        case .underlyingErrors(let errors, _, _):
            return "Check underlying errors' recovery suggestions for more information.\nRecovery Suggestions:\n\(errors.compactMap({ ($0 as NSError).localizedRecoverySuggestion }))"
        case .failedToPerform3dsButShouldContinue,
             .failedToPerform3dsAndShouldBreak,
             .noNeedToPerform3ds:
            return nil
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
        var context: [String: Any] = [: ]
        context[AnalyticsContextKeys.errorId] = errorId
        return context
    }
}
