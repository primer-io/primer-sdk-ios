//
//  Primer3DSErrorContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

public enum Primer3DSErrorContainer {
    // swiftlint:disable:next type_name
    @_spi(PrimerInternal) public typealias K = AnalyticsContextKeys

    case missingSdkDependency(diagnosticsId: String = .uuid)
    case invalid3DSSdkVersion(diagnosticsId: String = .uuid, invalidVersion: String?, validVersion: String)
    case missing3DSConfiguration(diagnosticsId: String = .uuid, missingKey: String)
    case primer3DSSdkError(
        paymentMethodType: String?,
        diagnosticsId: String = .uuid,
        initProtocolVersion: String?,
        errorInfo: Primer3DSErrorInfo
    )
    case underlyingError(diagnosticsId: String = .uuid, error: Error)

    public var errorId: String {
        switch self {
        case .missingSdkDependency:
            return "missing-sdk-dependency"
        case .invalid3DSSdkVersion:
            return "invalid-3ds-sdk-version"
        case .missing3DSConfiguration:
            return "missing-3ds-configuration"
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.errorId
        case let .underlyingError(_, err):
            if let primerErr = err as? PrimerError {
                return primerErr.errorId
            } else {
                let nsErr = err as NSError
                return nsErr.domain
            }
        }
    }
    
    public var errorDescription: String? {
        "[\(errorId)] \(plainDescription) (diagnosticsId: \(diagnosticsId))"
    }
    
    public var errorUserInfo: [String: Any] {
        info ?? [:]
    }

    public var diagnosticsId: String {
        switch self {
        case let .missingSdkDependency(diagnosticsId),
             let .invalid3DSSdkVersion(diagnosticsId, _, _),
             let .missing3DSConfiguration(diagnosticsId, _),
             let .primer3DSSdkError(_, diagnosticsId, _, _),
             let .underlyingError(diagnosticsId, _):
            return diagnosticsId
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingSdkDependency:
            return "Please follow the integration guide and include 3DS dependency."
        case let .invalid3DSSdkVersion(_, _, validVersion):
            return "Please update to Primer3DS v.\(validVersion)"
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.recoverySuggestion
        case .missing3DSConfiguration:
            return nil
        case let .underlyingError(_, err):
            if let primerErr = err as? PrimerError {
                return primerErr.recoverySuggestion
            } else {
                return nil
            }
        }
    }
    
    @_spi(PrimerInternal) public var plainDescription: String {
        switch self {
        case .missingSdkDependency:
            return "Cannot perform 3DS due to missing dependency."
        case .invalid3DSSdkVersion:
            return "Cannot perform 3DS due to library versions mismatch."
        case let .missing3DSConfiguration(_, missingKey):
            return "Cannot perform 3DS due to invalid 3DS configuration. 3DS Config \(missingKey) is missing"
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.errorDescription
        case let .underlyingError(_, err):
            if let primerErr = err as? PrimerError {
                return primerErr.plainDescription ?? primerErr.errorUserInfo.debugDescription
            } else {
                let nsErr = err as NSError
                return nsErr.description
            }
        }
    }

    @_spi(PrimerInternal) public var info: [String: Any]? {
        let tmpUserInfo: [String: String] = [K.createdAt: Date().toString()]
        return tmpUserInfo
    }

    @_spi(PrimerInternal) public var initProtocolVersion: String? {
        switch self {
        case .missingSdkDependency,
             .invalid3DSSdkVersion,
             .missing3DSConfiguration,
             .underlyingError:
            return nil
        case let .primer3DSSdkError(_, _, initProtocolVersion, _):
            return initProtocolVersion
        }
    }

    @_spi(PrimerInternal) public var threeDsErrorDescription: String? {
        switch self {
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.errorDescription
        case let .underlyingError(_, err):
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

    @_spi(PrimerInternal) public var threeDsErrorCode: Int? {
        switch self {
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.threeDsErrorCode
        default:
            return nil
        }
    }

    @_spi(PrimerInternal) public var threeDsErrorType: String? {
        switch self {
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.threeDsErrorType
        default:
            return nil
        }
    }

    @_spi(PrimerInternal) public var threeDsErrorComponent: String? {
        switch self {
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.threeDsErrorComponent
        default:
            return nil
        }
    }

    @_spi(PrimerInternal) public var threeDsSdkTranscationId: String? {
        switch self {
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.threeDsSdkTranscationId
        default:
            return nil
        }
    }

    @_spi(PrimerInternal) public var threeDsSErrorVersion: String? {
        switch self {
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.threeDsSErrorVersion
        default:
            return nil
        }
    }

    @_spi(PrimerInternal) public var threeDsErrorDetail: String? {
        switch self {
        case let .primer3DSSdkError(_, _, _, errorInfo):
            return errorInfo.threeDsErrorDetail
        default:
            return nil
        }
    }
}
