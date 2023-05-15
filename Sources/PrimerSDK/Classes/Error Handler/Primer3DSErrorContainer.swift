//
//  Primer3DSErrorContainer.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 12/5/23.
//

#if canImport(UIKit)

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
    
    case missingSdkDependency(userInfo: [String: String]?, diagnosticsId: String)
    case invalid3DSSdkVersion(userInfo: [String: String]?, diagnosticsId: String, invalidVersion: String?, validVersion: String)
    case missing3DSConfiguration(userInfo: [String: String]?, diagnosticsId: String, missingKey: String)
    case primer3DSSdkError(userInfo: [String: String]?, diagnosticsId: String, initProtocolVersion: String?, errorInfo: Primer3DSErrorInfo)
    
    public var errorId: String {
        switch self {
        case .missingSdkDependency:
            return "missing-sdk-dependency"
        case .invalid3DSSdkVersion:
            return "invalid-3ds-sdk-version"
        case .missing3DSConfiguration:
            return "missing-3ds-configuration"
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.errorId
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
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.errorDescription
        }
    }
    
    public var errorDescription: String? {
        return "[\(errorId)] \(plainDescription) (diagnosticsId: \(self.diagnosticsId))"
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .missingSdkDependency:
            return "Please follow the integration guide and include 3DS dependency."
        case .invalid3DSSdkVersion(_, _, _, let validVersion):
            return "Please update to Primer3DS v.\(validVersion)"
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.recoverySuggestion
        case .missing3DSConfiguration:
            return nil
        }
    }
    
    var exposedError: Error {
        return self
    }
    
    internal var info: [String: Any]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]
        return tmpUserInfo
    }
    
    public var errorUserInfo: [String : Any] {
        return info ?? [:]
    }
    
    internal var diagnosticsId: String {
        switch self {
        case .missingSdkDependency(_, let diagnosticsId),
                .invalid3DSSdkVersion(_, let diagnosticsId, _, _),
                .missing3DSConfiguration(_, let diagnosticsId, _),
                .primer3DSSdkError(_, let diagnosticsId, _, _):
            return diagnosticsId
        }
    }
    
    internal var initProtocolVersion: String? {
        switch self {
        case .missingSdkDependency,
                .invalid3DSSdkVersion,
                .missing3DSConfiguration:
            return nil
        case .primer3DSSdkError(_, _, let initProtocolVersion, _):
            return initProtocolVersion
        }
    }
    
    internal var continueInfo: ThreeDS.ContinueInfo {
        return ThreeDS.ContinueInfo.init(initProtocolVersion: self.initProtocolVersion, error: self)
    }
    
    internal var threeDsErrorDescription: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.errorDescription
        default:
            return nil
        }
    }
    
    internal var threeDsErrorCode: Int? {
        switch self {
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.threeDsErrorCode
        default:
            return nil
        }
    }
    
    internal var threeDsErrorType: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.threeDsErrorType
        default:
            return nil
        }
    }
    
    internal var threeDsErrorComponent: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.threeDsErrorComponent
        default:
            return nil
        }
    }
    
    internal var threeDsSdkTranscationId: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.threeDsSdkTranscationId
        default:
            return nil
        }
    }
    
    internal var threeDsSErrorVersion: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.threeDsSErrorVersion
        default:
            return nil
        }
    }
    
    internal var threeDsErrorDetail: String? {
        switch self {
        case .primer3DSSdkError(_, _, _, let errorInfo):
            return errorInfo.threeDsErrorDetail
        default:
            return nil
        }
    }
}

#endif
