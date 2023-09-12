//
//  Primer3DSError.swift
//  Primer3DS
//
//  Created by Evangelos Pittas on 12/5/23.
//

#if canImport(UIKit)

import Foundation

public enum Primer3DSError: CustomNSError, LocalizedError {
    
    case initializationError(error: Error?, warnings: String?)
    case missingDsRid(cardNetwork: String)
    case unsupportedProtocolVersion(supportedProtocols: [String])
    case failedToCreateTransaction(error: Error)
    case timeOut
    case cancelled
    case challengeFailed(error: Error)
    case invalidChallengeStatus(status: String, sdkTransactionId: String)
    case protocolError(description: String, code: String, type: String, component: String, transactionId: String, protocolVersion: String, details: String?)
    case runtimeError(description: String, code: String?)
    case unknown(description: String)
    
    public var errorId: String {
        switch self {
        case .initializationError:
            return "3ds-sdk-init-failed"
        case .missingDsRid:
            return "missing-ds-rid"
        case .unsupportedProtocolVersion:
            return "unsupported-protocol-version"
        case .challengeFailed:
            return "3ds-challenge-failed"
        case .invalidChallengeStatus:
            return "3ds-challenge-failed"
        case .timeOut:
            return "3ds-challenge-timed-out"
        case .cancelled:
            return "3ds-challenge-cancelled-by-the-user"
        case .failedToCreateTransaction:
            return "failed-to-create-3ds-transaction"
        case .protocolError:
            return "3ds-sdk-protocol-error"
        case .runtimeError:
            return "3ds-sdk-runtime-error"
        case .unknown:
            return "unknown"
        }
    }
    
    var underlyingError: Error? {
        switch self {
        case .initializationError(let error, _):
            return error
        case .failedToCreateTransaction(let error),
                .challengeFailed(let error):
            return error
        default:
            return nil
        }
    }
    
    public var errorDescription: String {
        switch self {
        case .initializationError(let error, let warnings):
            if let error = error, let warnings = warnings, !warnings.isEmpty {
                return "Primer3DS SDK init failed with error '\((error as NSError).description)' and warnings '\(warnings)'."
            } else if let error = error {
                return "Primer3DS SDK init failed with error '\((error as NSError).description)'."
            } else if let warnings = warnings {
                return "Primer3DS SDK init failed with warnings '\(warnings)'."
            } else {
                return "Primer3DS SDK init failed."
            }
        case .missingDsRid(let cardNetwork):
            return "Cannot perform 3DS due to missing directory server RID for \(cardNetwork)."
        case .unsupportedProtocolVersion(let supportedProtocols):
            return "Primer3DS SDK received unsupported protocol versions [\(supportedProtocols.joined(separator: ", "))]"
        case .failedToCreateTransaction(let error):
            return "Primer3DS SDK failed to create 3DS transaction object with error '\((error as NSError).description)'."
        case .timeOut:
            return "3DS Challenge timed out."
        case .cancelled:
            return "3DS Challenge cancelled by user."
        case .challengeFailed(let error):
            return "3DS challenge failed with error '\((error as NSError).description)'."
        case .invalidChallengeStatus(let status, let sdkTransactionId):
            return "3DS challenge for transaction with id '\(sdkTransactionId)' failed with status '\(status)'."
        case .protocolError(let description, _, _, _, _, _, _):
            return description
        case .runtimeError(let description, _):
            return description
        case .unknown(let description):
            return description
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .initializationError:
            return "If this application is not installed from a trusted source (e.g. a debug version, or used on an simulator), try to set 'PrimerDebugOptions.is3DSSanityCheckEnabled' to false."
        case .missingDsRid:
            return nil
        case .unsupportedProtocolVersion:
            return nil
        case .failedToCreateTransaction:
            return nil
        case .timeOut:
            return nil
        case .cancelled:
            return nil
        case .challengeFailed:
            return nil
        case .invalidChallengeStatus:
            return nil
        case .protocolError:
            return nil
        case .runtimeError:
            return nil
        case .unknown:
            return nil
        }
    }
    
    public var errorUserInfo: [String : Any] {
        guard let underlyingError = underlyingError else { return [:] }
        let nsErr = underlyingError as NSError
        return nsErr.userInfo
    }
    
    public var threeDsErrorCode: Int? {
        switch self {
        case .timeOut:
            return -3
        case .cancelled:
            return -4
        case .initializationError(let error, _):
            return (error as NSError?)?.code
        case .missingDsRid:
            return nil
        case .unsupportedProtocolVersion:
            return nil
        case .failedToCreateTransaction(error: let error):
            return (error as NSError).code
        case .challengeFailed(error: let error):
            return (error as NSError).code
        case .invalidChallengeStatus:
            return -5
        case .protocolError(_, let code, _, _, _, _, _):
            return Int(code)
        case .runtimeError(_, let code):
            guard let code = code else { return nil }
            return Int(code)
        case .unknown:
            return nil
        }
    }
    
    public var threeDsErrorType: String? {
        switch self {
        case .protocolError(_, _, let type, _, _, _, _):
            return type
        default:
            return nil
        }
    }
    
    public var threeDsErrorComponent: String? {
        switch self {
        case .protocolError(_, _, _, let component, _, _, _):
            return component
        default:
            return nil
        }
    }
    
    public var threeDsSdkTranscationId: String? {
        switch self {
        case .protocolError(_, _, _, _, let transactionId, _, _):
            return transactionId
        default:
            return nil
        }
    }
    
    public var threeDsSErrorVersion: String? {
        switch self {
        case .protocolError(_, _, _, _, _, let protocolVersion, _):
            return protocolVersion
        default:
            return nil
        }
    }
    
    public var threeDsErrorDetail: String? {
        switch self {
        case .protocolError(_, _, _, _, _, _, let detail):
            return detail
        default:
            return nil
        }
    }
}

#endif
