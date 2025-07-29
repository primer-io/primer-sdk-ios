//
//  Primer3DSErrorContainer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct Primer3DSErrorInfo {
    let errorId: String
    let errorDescription: String
    let recoverySuggestion: String?
    let threeDsErrorCode: Int?
    let threeDsErrorType: String?
    let threeDsErrorComponent: String?
    let threeDsSdkTranscationId: String?
    let threeDsSErrorVersion: String?
    let threeDsErrorDetail: String?
}

public enum Primer3DSErrorContainer: PrimerErrorProtocol {
    // swiftlint:disable:next type_name
    typealias K = AnalyticsContextKeys

    case missingSdkDependency(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalid3DSSdkVersion(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid,
        invalidVersion: String?,
        validVersion: String
    )
    case missing3DSConfiguration(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid,
        missingKey: String
    )
    case primer3DSSdkError(
        paymentMethodType: String?,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid,
        initProtocolVersion: String?,
        errorInfo: Primer3DSErrorInfo
    )
    case underlyingError(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid,
        error: Error
    )

    public var errorId: String {
        switch self {
        case .missingSdkDependency:
            return "missing-sdk-dependency"
        case .invalid3DSSdkVersion:
            return "invalid-3ds-sdk-version"
        case .missing3DSConfiguration:
            return "missing-3ds-configuration"
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.errorId
        case .underlyingError(_, _, let err):
            if let primerErr = err as? PrimerError {
                return primerErr.errorId
            } else {
                let nsErr = err as NSError
                return nsErr.domain
            }
        }
    }

    var plainDescription: String {
        switch self {
        case .missingSdkDependency:
            return "Cannot perform 3DS due to missing dependency."
        case .invalid3DSSdkVersion:
            return "Cannot perform 3DS due to library versions mismatch."
        case .missing3DSConfiguration(_, _, let missingKey):
            return "Cannot perform 3DS due to invalid 3DS configuration. 3DS Config \(missingKey) is missing"
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.errorDescription
        case .underlyingError(_, _, let err):
            if let primerErr = err as? PrimerError {
                return primerErr.plainDescription ?? primerErr.errorUserInfo.debugDescription
            } else {
                let nsErr = err as NSError
                return nsErr.description
            }
        }
    }

    public var errorDescription: String? {
        "[\(errorId)] \(plainDescription) (diagnosticsId: \(diagnosticsId))"
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingSdkDependency:
            return "Please follow the integration guide and include 3DS dependency."
        case .invalid3DSSdkVersion(_, _, _, let validVersion):
            return "Please update to Primer3DS v.\(validVersion)"
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.recoverySuggestion
        case .missing3DSConfiguration:
            return nil
        case .underlyingError(_, _, let err):
            if let primerErr = err as? PrimerError {
                return primerErr.recoverySuggestion
            } else {
                return nil
            }
        }
    }

    var exposedError: Error {
        return self
    }

    var analyticsContext: [String: Any] {
        var context: [String: Any] = [:]

        context[K.initProtocolVersion] = continueInfo.initProtocolVersion
        context[K.threeDsSdkVersion] = continueInfo.threeDsSdkVersion
        context[K.threeDsSdkProvider] = continueInfo.threeDsSdkProvider
        context[K.threeDsWrapperSdkVersion] = continueInfo.threeDsWrapperSdkVersion

        switch self {
        case .primer3DSSdkError(let paymentMethodType, _, _, _, let errorInfo):
            context[K.reasonCode] = errorInfo.errorId
            context[K.reasonText] = errorInfo.errorDescription
            context[K.threeDsErrorCode] = errorInfo.threeDsErrorCode
            context[K.threeDsErrorComponent] = errorInfo.threeDsErrorComponent
            context[K.threeDsErrorDescription] = errorInfo.errorDescription
            context[K.threeDsErrorDetail] = errorInfo.threeDsErrorDetail
            context[K.threeDsSdkTranscationId] = errorInfo.threeDsSdkTranscationId
            context[K.protocolVersion] = errorInfo.threeDsSErrorVersion
            context[K.errorId] = errorInfo.errorId
            if let paymentMethodType = paymentMethodType {
                context[K.paymentMethodType] = paymentMethodType
            }
        default:
            break
        }

        return context
    }

    var info: [String: Any]? {
        let tmpUserInfo: [String: String] = [K.createdAt: Date().toString()]
        return tmpUserInfo
    }

    public var errorUserInfo: [String: Any] {
        return info ?? [:]
    }

    var diagnosticsId: String {
        switch self {
        case .missingSdkDependency(_, let diagnosticsId),
             .invalid3DSSdkVersion(_, let diagnosticsId, _, _),
             .missing3DSConfiguration(_, let diagnosticsId, _),
             .primer3DSSdkError(_, _, let diagnosticsId, _, _),
             .underlyingError(_, let diagnosticsId, _):
            return diagnosticsId
        }
    }

    var initProtocolVersion: String? {
        switch self {
        case .missingSdkDependency,
             .invalid3DSSdkVersion,
             .missing3DSConfiguration,
             .underlyingError:
            return nil
        case .primer3DSSdkError(_, _, _, let initProtocolVersion, _):
            return initProtocolVersion
        }
    }

    var continueInfo: ThreeDS.ContinueInfo {
        ThreeDS.ContinueInfo(initProtocolVersion: initProtocolVersion, error: self)
    }

    var threeDsErrorDescription: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.errorDescription
        case .underlyingError(_, _, let err):
            if let primerErr = err as? PrimerError {
                return primerErr.plainDescription
            } else {
                let nsErr = err as NSError
                return nsErr.debugDescription
            }
        default:
            return nil
        }
    }

    var threeDsErrorCode: Int? {
        switch self {
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.threeDsErrorCode
        default:
            return nil
        }
    }

    var threeDsErrorType: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.threeDsErrorType
        default:
            return nil
        }
    }

    var threeDsErrorComponent: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.threeDsErrorComponent
        default:
            return nil
        }
    }

    var threeDsSdkTranscationId: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.threeDsSdkTranscationId
        default:
            return nil
        }
    }

    var threeDsSErrorVersion: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.threeDsSErrorVersion
        default:
            return nil
        }
    }

    var threeDsErrorDetail: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, _, let errorInfo):
            return errorInfo.threeDsErrorDetail
        default:
            return nil
        }
    }
}

extension AnalyticsContextKeys {
    static let initProtocolVersion = "initProtocolVersion"
    static let threeDsSdkVersion = "threeDsSdkVersion"
    static let threeDsSdkProvider = "threeDsSdkProvider"
    static let threeDsWrapperSdkVersion = "threeDsWrapperSdkVersion"
    static let threeDsErrorCode = "threeDsErrorCode"
    static let threeDsErrorComponent = "threeDsErrorComponent"
    static let threeDsErrorDescription = "threeDsErrorDescription"
    static let threeDsErrorDetail = "threeDsErrorDetail"
    static let threeDsSdkTranscationId = "threeDsSdkTranscationId"
    static let protocolVersion = "protocolVersion"
}
