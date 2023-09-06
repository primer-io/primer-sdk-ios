
import Foundation

// Exposed structures

public enum Environment: String, Codable {
    case production = "PRODUCTION"
    case staging = "STAGING"
    case sandbox = "SANDBOX"
    case local = "LOCAL"
    case dev = "DEV"
}

@objc public enum ResponseCode: Int {
    case notPerformed = 1
    case skipped = 2
    case authSuccess = 3
    case authFailed = 4
    case challenge = 5
    case method = 6
    
    init(responseCode: String) {
        switch responseCode {
        case ResponseCode.notPerformed.stringValue:
            self = .notPerformed
        case ResponseCode.skipped.stringValue:
            self = .skipped
        case ResponseCode.authSuccess.stringValue:
            self = .authSuccess
        case ResponseCode.authFailed.stringValue:
            self = .authFailed
        case ResponseCode.challenge.stringValue:
            self = .challenge
        case ResponseCode.method.stringValue:
            self = .method
        default:
            fatalError("Primer3DS ResponseCode cannot be initialized with '\(responseCode)'")
        }
    }
    
    var stringValue: String {
        switch self {
        case .notPerformed:
            return "NOT_PERFORMED"
        case .skipped:
            return "SKIPPED"
        case .authSuccess:
            return "AUTH_SUCCESS"
        case .authFailed:
            return "AUTH_FAILED"
        case .challenge:
            return "CHALLENGE"
        case .method:
            return "METHOD"
        }
    }
}

@objc internal class SDKAuthData: NSObject, Primer3DSSDKGeneratedAuthData {
    
    var sdkAppId: String
    var sdkTransactionId: String
    var sdkTimeout: Int
    var sdkEncData: String
    var sdkEphemPubKey: String
    var sdkReferenceNumber: String
    
    init(sdkAppId: String, sdkTransactionId: String, sdkTimeout: Int, sdkEncData: String, sdkEphemPubKey: String, sdkReferenceNumber: String) {
        self.sdkAppId = sdkAppId
        self.sdkTransactionId = sdkTransactionId
        self.sdkTimeout = sdkTimeout
        self.sdkEncData = sdkEncData
        self.sdkEphemPubKey = sdkEphemPubKey
        self.sdkEphemPubKey = sdkEphemPubKey
        self.sdkReferenceNumber = sdkReferenceNumber
        super.init()
    }
}

@objc public class SDKAuthResult: NSObject {
    
    public var authData: Primer3DSSDKGeneratedAuthData
    public var maxSupportedThreeDsProtocolVersion: String
    
    init(authData: Primer3DSSDKGeneratedAuthData, maxSupportedThreeDsProtocolVersion: String) {
        self.authData = authData
        self.maxSupportedThreeDsProtocolVersion = maxSupportedThreeDsProtocolVersion
        super.init()
    }
}

@objc internal class AuthCompletion: NSObject, Primer3DSCompletion {
    public let sdkTransactionId: String
    public let transactionStatus: String
    
    init(sdkTransactionId: String, transactionStatus: String) {
        self.sdkTransactionId = sdkTransactionId
        self.transactionStatus = transactionStatus
    }
}

internal enum AuthenticationStatus: String {
    case y, a, n, u, e
    
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "y":
            self = AuthenticationStatus.y
        case "a":
            self = AuthenticationStatus.a
        case "n":
            self = AuthenticationStatus.n
        case "u":
            self = AuthenticationStatus.u
        case "e":
            self = AuthenticationStatus.e
        default:
            self = AuthenticationStatus.e
        }
    }
    
    var `description`: String {
        switch self {
        case .y:
            return "Authentication successful"
        case .a:
            return "Authentication attempted"
        case .n:
            return "Authentication failed"
        case .u:
            return "Authentication unavailable"
        case .e:
            return "Error"
        }
    }
    
    var recommendation: AuthenticationRecommendation {
        switch self {
        case .y,
             .a:
            return .proceed
        case .n,
             .e:
            return .stop
        case .u:
            return .merchantDecision
        }
    }
}

internal enum AuthenticationRecommendation {
    case proceed, stop, merchantDecision
}

