//
//  3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 1/4/21.
//

import Foundation
#if canImport(Primer3DS)
import Primer3DS
#endif

protocol ThreeDSAuthenticationProtocol: Codable {

    var acsReferenceNumber: String? { get }
    var acsSignedContent: String? { get }
    var acsTransactionId: String? { get }
    var responseCode: ThreeDS.ResponseCode { get }
    var transactionId: String? { get }
}

protocol ThreeDSSDKAuthDataProtocol: Codable {

    var sdkAppId: String { get }
    var sdkTransactionId: String { get }
    var sdkTimeout: Int { get }
    var sdkEncData: String { get }
    var sdkEphemPubKey: String { get }
    var sdkReferenceNumber: String { get }
}

public class ThreeDS {

    #if canImport(Primer3DS)
    class Cer: Primer3DSCertificate {

        var cardScheme: String
        var encryptionKey: String
        var rootCertificate: String

        init(cardScheme: String, rootCertificate: String, encryptionKey: String) {
            self.cardScheme = cardScheme
            self.rootCertificate = rootCertificate
            self .encryptionKey = encryptionKey
        }
    }

    class ServerAuthData: Primer3DSServerAuthData {

        var acsReferenceNumber: String?
        var acsSignedContent: String?
        var acsTransactionId: String?
        var responseCode: String
        var transactionId: String?

        init(acsReferenceNumber: String?,
             acsSignedContent: String?,
             acsTransactionId: String?,
             responseCode: String,
             transactionId: String?) {

            self.acsReferenceNumber = acsReferenceNumber
            self.acsSignedContent = acsSignedContent
            self.acsTransactionId = acsTransactionId
            self.responseCode = responseCode
            self.transactionId = transactionId
        }
    }
    #endif

    internal struct Keys: Codable {

        let threeDSecureIoCertificates: [ThreeDS.Certificate]?
        let netceteraApiKey: String?
    }

    internal struct Certificate: Codable {

        let encryptionKey: String
        let cardNetwork: String
        let rootCertificate: String
    }

    internal enum ChallengePreference: String, Codable {

        case noPreference           = "NO_PREFERENCE"
        case requestedByRequestor   = "REQUESTED_BY_REQUESTOR"
        case requestedDueToMandate  = "REQUESTED_DUE_TO_MANDATE"
    }

    internal struct ACSRenderingType: Codable {

        let acsInterface: String?
        let acsUiTemplate: String?
    }

    internal enum AuthenticationStatus: String {
        // swiftlint:disable:next identifier_name
        case y, a, n, u, e

        init(rawValue: String) {
            switch rawValue.lowercased() {
            case "y":
                self = ThreeDS.AuthenticationStatus.y
            case "a":
                self = ThreeDS.AuthenticationStatus.a
            case "n":
                self = ThreeDS.AuthenticationStatus.n
            case "u":
                self = ThreeDS.AuthenticationStatus.u
            case "e":
                self = ThreeDS.AuthenticationStatus.e
            default:
                self = ThreeDS.AuthenticationStatus.e
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
            case .y, .a:
                return .proceed
            case .n, .e:
                return .stop
            case .u:
                return .merchantDecision
            }
        }
    }

    internal enum AuthenticationRecommendation {
        case proceed, stop, merchantDecision
    }

    internal enum TestScenario: String, Codable {

        case three3DS2MethodTimeout = "3DS_V2_METHOD_TIMEOUT"
        case threeDS2FrictionlessNoMethod = "3DS_V2_FRICTIONLESS_NO_METHOD"
        case threeDS2FrictionlessPass = "3DS_V2_FRICTIONLESS_PASS"
        case threeDS2ManualChallengePass = "3DS_V2_MANUAL_CHALLENGE_PASS"
        case threeDS2AutoChallengePass = "3DS_V2_AUTO_CHALLENGE_PASS"
        case threeDS2AutoChallengeFail = "3DS_V2_AUTO_CHALLENGE_FAIL"
        case threeDS2AutoChallengePassNoMethod = "3DS_V2_AUTO_CHALLENGE_PASS_NO_METHOD"
        case threeDS2FrictionlessFailureN = "3DS_V2_FRICTIONLESS_FAILURE_N"
        case threeDS2FrictionlessFailureU = "3DS_V2_FRICTIONLESS_FAILURE_U"
        case threeDS2FrictionlessFailureR = "3DS_V2_FRICTIONLESS_FAILURE_R"
        case threeDS2FrictionlessFailureAttempted = "3DS_V2_FRICTIONLESS_FAILURE_ATTEMPTED"
        case threeDS2DSTimeout = "3DS_V2_DS_TIMEOUT"
    }

    internal struct SDKAuthData: ThreeDSSDKAuthDataProtocol {

        var sdkAppId: String
        var sdkTransactionId: String
        var sdkTimeout: Int
        var sdkEncData: String
        var sdkEphemPubKey: String
        var sdkReferenceNumber: String
    }

    internal struct BeginAuthRequest: Codable {

        let maxProtocolVersion: String
        let device: ThreeDS.SDKAuthData
    }

    internal enum Status: String, Codable {
        case success = "SUCCESS"
        case failure = "FAILURE"
    }

    internal enum ProtocolVersion: String, Codable {
        // swiftlint:disable identifier_name
        case v_2_1_0 = "2.1.0"
        case v_2_2_0 = "2.2.0"
        // swiftlint:enable identifier_name

        init?(rawValue: String) {
            if rawValue == ProtocolVersion.v_2_1_0.rawValue {
                self = ProtocolVersion.v_2_1_0
            } else if rawValue == ProtocolVersion.v_2_2_0.rawValue {
                self = ProtocolVersion.v_2_2_0
            } else {
                if (rawValue.compareWithVersion("2.1") == .orderedSame) ||
                    (rawValue.compareWithVersion("2.1") == .orderedDescending
                        && rawValue.compareWithVersion("2.2") == .orderedAscending) {
                    self = ProtocolVersion.v_2_1_0

                } else if (rawValue.compareWithVersion("2.2") == .orderedSame) ||
                            (rawValue.compareWithVersion("2.2") == .orderedDescending
                                && rawValue.compareWithVersion("2.3") == .orderedAscending) {
                    self = ProtocolVersion.v_2_2_0
                } else {
                    return nil
                }
            }
        }
    }

    internal struct ThreeDSSDKAuthCompletion {

        let sdkTransactionId: String
        let transactionStatus: ThreeDS.AuthenticationStatus
    }

    internal struct Customer: Codable {

        let name: String
        let email: String
        let homePhone: String?
        let mobilePhone: String?
        let workPhone: String?
    }

    internal struct Device: Codable {
        let sdkTransactionId: String
    }

    internal struct Address: Codable {

        let title: String?
        let firstName: String?
        let lastName: String?
        let email: String?
        let phoneNumber: String?
        let addressLine1: String?
        let addressLine2: String?
        let addressLine3: String?
        let city: String?
        let state: String?
        let countryCode: CountryCode?
        let postalCode: String?

        func encode(to encoder: Encoder) throws {
            // Only take into account address fields
            if self.firstName == nil,
               self.lastName == nil,
               self.addressLine1 == nil,
               self.addressLine2 == nil,
               self.addressLine3 == nil,
               self.city == nil,
               self.state == nil,
               self.countryCode == nil,
               self.postalCode == nil {
                var container = encoder.singleValueContainer()
                try container.encodeNil()

            } else {
                var container = encoder.container(keyedBy: ThreeDS.Address.CodingKeys.self)
                try container.encodeIfPresent(self.title, forKey: ThreeDS.Address.CodingKeys.title)
                try container.encodeIfPresent(self.firstName, forKey: ThreeDS.Address.CodingKeys.firstName)
                try container.encodeIfPresent(self.lastName, forKey: ThreeDS.Address.CodingKeys.lastName)
                try container.encodeIfPresent(self.email, forKey: ThreeDS.Address.CodingKeys.email)
                try container.encodeIfPresent(self.phoneNumber, forKey: ThreeDS.Address.CodingKeys.phoneNumber)
                try container.encodeIfPresent(self.addressLine1, forKey: ThreeDS.Address.CodingKeys.addressLine1)
                try container.encodeIfPresent(self.addressLine2, forKey: ThreeDS.Address.CodingKeys.addressLine2)
                try container.encodeIfPresent(self.addressLine3, forKey: ThreeDS.Address.CodingKeys.addressLine3)
                try container.encodeIfPresent(self.city, forKey: ThreeDS.Address.CodingKeys.city)
                try container.encodeIfPresent(self.state, forKey: ThreeDS.Address.CodingKeys.state)
                try container.encodeIfPresent(self.countryCode, forKey: ThreeDS.Address.CodingKeys.countryCode)
                try container.encodeIfPresent(self.postalCode, forKey: ThreeDS.Address.CodingKeys.postalCode)
            }
        }
    }

    internal struct CustomerAccount: Codable {

        let id: String?
        let createdAt: String?
        let updatedAt: String?
        let passwordUpdatedAt: String?
        let purchaseCount: Int?
    }

    public enum ResponseCode: String, Codable {

        case notPerformed = "NOT_PERFORMED"
        case skipped = "SKIPPED"
        case authSuccess = "AUTH_SUCCESS"
        case authFailed = "AUTH_FAILED"
        case challenge = "CHALLENGE"
        case METHOD = "METHOD"
    }

    internal enum SkippedCode: String, Codable {

        case gatewayUnavailable = "GATEWAY_UNAVAILABLE"
        case disabledByMerchant = "DISABLED_BY_MERCHANT"
        case notSupportedByIssuer = "NOT_SUPPORTED_BY_ISSUER"
        case failedToNegotiate = "FAILED_TO_NEGOTIATE"
        case unknownACSResponse = "UNKNOWN_ACS_RESPONSE"
        case threeDSServerError = "3DS_SERVER_ERROR"
        case acquirerNotConfigured = "ACQUIRER_NOT_CONFIGURED"
        case acquirerNotParticipating = "ACQUIRER_NOT_PARTICIPATING"

    }

    internal struct BeginAuthResponse: Decodable {

        let authentication: ThreeDSAuthenticationProtocol
        let token: PrimerPaymentMethodTokenData
        let resumeToken: String
        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case authentication
            case token
            case resumeToken
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let declinedResponse = try? container.decode(ThreeDS.DeclinedAPIResponse.self,
                                                            forKey: .authentication) {
                authentication = declinedResponse
            } else if let skippedResponse = try? container.decode(ThreeDS.SkippedAPIResponse.self,
                                                                  forKey: .authentication) {
                authentication = skippedResponse
            } else if let appV2ChallengeResponse = try? container.decode(ThreeDS.AppV2ChallengeAPIResponse.self,
                                                                         forKey: .authentication) {
                authentication = appV2ChallengeResponse
            } else if let browserV2ChallengeResponse = try? container.decode(ThreeDS.BrowserV2ChallengeAPIResponse.self,
                                                                             forKey: .authentication) {
                authentication = browserV2ChallengeResponse
            } else if let browserV1ChallengeResponse = try? container.decode(ThreeDS.BrowserV1ChallengeAPIResponse.self,
                                                                             forKey: .authentication) {
                authentication = browserV1ChallengeResponse
            } else if let successResponse = try? container.decode(Authentication.self,
                                                                  forKey: .authentication) {
                authentication = successResponse
            } else if let methodResponse = try? container.decode(ThreeDS.MethodAPIResponse.self,
                                                                 forKey: .authentication) {
                authentication = methodResponse
            } else {
                let err = InternalError.failedToDecode(message: "ThreeDS.BeginAuthResponse",
                                                       userInfo: ["file": #file,
                                                                  "class": "\(Self.self)",
                                                                  "function": #function,
                                                                  "line": "\(#line)"],
                                                       diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            resumeToken = try container.decode(String.self, forKey: .resumeToken)
            token = try container.decode(PrimerPaymentMethodTokenData.self, forKey: .token)
        }

        init(
            authentication: ThreeDSAuthenticationProtocol,
            token: PrimerPaymentMethodTokenData,
            resumeToken: String
        ) {
            self.authentication = authentication
            self.token = token
            self.resumeToken = resumeToken
        }
    }

    internal struct PostAuthResponse: Codable {

        let token: PrimerPaymentMethodTokenData
        let resumeToken: String
        let authentication: Authentication?
    }

    internal struct Authentication: ThreeDSAuthenticationProtocol {

        let acsReferenceNumber: String?
        let acsSignedContent: String?
        let acsTransactionId: String?
        let responseCode: ThreeDS.ResponseCode
        let transactionId: String?
        let acsOperatorId: String?
        let cryptogram: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let protocolVersion: String?
        let xid: String?

        init(acsReferenceNumber: String?,
             acsSignedContent: String?,
             acsTransactionId: String?,
             responseCode: ThreeDS.ResponseCode,
             transactionId: String?,
             acsOperatorId: String?,
             cryptogram: String?,
             dsReferenceNumber: String?,
             dsTransactionId: String?,
             eci: String?,
             protocolVersion: String,
             xid: String?) {

            self.acsReferenceNumber = acsReferenceNumber
            self.acsSignedContent = acsSignedContent
            self.acsTransactionId = acsTransactionId
            self.responseCode = responseCode
            self.transactionId = transactionId
            self.acsOperatorId = acsOperatorId
            self.cryptogram = cryptogram
            self.dsReferenceNumber = dsReferenceNumber
            self.dsTransactionId = dsTransactionId
            self.eci = eci
            self.protocolVersion = protocolVersion
            self.xid = xid
        }
    }

    internal struct SkippedAPIResponse: ThreeDSAuthenticationProtocol, Codable {

        let acsReferenceNumber: String?
        let acsSignedContent: String?
        let acsTransactionId: String?
        let responseCode: ThreeDS.ResponseCode
        let transactionId: String?
        let acsChallengeMandated: Int?
        let acsOperatorId: String?
        let acsRenderingType: ACSRenderingType?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let protocolVersion: String?
        let skippedReasonCode: ThreeDS.SkippedCode
        let skippedReasonText: String
        let statusUrl: String?
    }

    internal struct MethodAPIResponse: ThreeDSAuthenticationProtocol {

        let acsReferenceNumber: String?
        let acsSignedContent: String?
        let acsTransactionId: String?
        let responseCode: ThreeDS.ResponseCode
        let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let acsMethodUrl: String?
        let notificationUrl: String?
        let statusUrl: String?
    }

    internal struct BrowserV2ChallengeAPIResponse: ThreeDSAuthenticationProtocol {

        let acsReferenceNumber: String?
        let acsSignedContent: String?
        let acsTransactionId: String?
        let responseCode: ThreeDS.ResponseCode
        let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String
        let eci: String?
        let acsChallengeUrl: String
        let acsChallengeMandated: String
        let statusUrl: String
        let challengeWindowSize: String
    }

    internal struct AppV2ChallengeAPIResponse: ThreeDSAuthenticationProtocol {

        let acsReferenceNumber: String?
        let acsSignedContent: String?
        let acsTransactionId: String?
        let responseCode: ThreeDS.ResponseCode
        let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String
        let eci: String?
        let acsRenderingType: String
        let acsChallengeMandated: String
        let statusUrl: String
    }

    internal struct BrowserV1ChallengeAPIResponse: ThreeDSAuthenticationProtocol {

        let acsRefNumber: String?
        let acsSignedContent: String?
        let acsTransactionId: String?
        let responseCode: ThreeDS.ResponseCode
        let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        let acsReferenceNumber: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let acsChallengeUrl: String
        let acsChallengeData: String
        let statusUrl: String
        let notificationUrl: String
        let challengeWindowSize: String
    }

    internal struct DeclinedAPIResponse: ThreeDSAuthenticationProtocol {

        let acsRefNumber: String?
        let acsSignedContent: String?
        let acsTransactionId: String?
        let responseCode: ThreeDS.ResponseCode
        let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        let acsReferenceNumber: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let declinedReasonCode: ThreeDS.DeclinedReasonCode
        let declinedReasonText: String
    }

    public struct AuthenticationDetails: Codable {

        public let responseCode: ResponseCode
        public let reasonCode, reasonText, protocolVersion: String?
        public let challengeIssued: Bool?
    }

    internal enum DeclinedReasonCode: String, Codable {

        case unknown = "UNKNOWN"
        case rejectedByIssuer = "REJECTED_BY_ISSUER"
        case cardAuthenticationFailed = "CARD_AUTHENTICATION_FAILED"
        case unknownDevice = "UNKNOWN_DEVICE"
        case unsupportedDevice = "UNSUPPORTED_DEVICE"
        case exceedsAuthenticationFrequencyLimit = "EXCEEDS_AUTHENTICATION_FREQUENCY_LIMIT"
        case expiredCard = "EXPIRED_CARD"
        case invalidCardNumber = "INVALID_CARD_NUMBER"
        case invalidTransaction = "INVALID_TRANSACTION"
        case noCardRecord = "NO_CARD_RECORD"
        case securityFailure = "SECURITY_FAILURE"
        case stolenCard = "STOLEN_CARD"
        case suspectedFraud = "SUSPECTED_FRAUD"
        case transactionNotPermittedToCardholder = "TRANSACTION_NOT_PERMITTED_TO_CARDHOLDER"
        case cardholderNotEnrolledInService = "CARDHOLDER_NOT_ENROLLED_IN_SERVICE"
        case transactionTimedOutAtTheACS = "TRANSACTION_TIMED_OUT_AT_THE_ACS"
        case lowConfidence = "LOW_CONFIDENCE"
        case mediumConfidence = "MEDIUM_CONFIDENCE"
        case highConfidence = "HIGH_CONFIDENCE"
        case veryHighConfidence = "VERY_HIGH_CONFIDENCE"
        case exceedsACSMaximumChallenges = "EXCEEDS_ACS_MAXIMUM_CHALLENGES"
        case nonPaymentNotSupported = "NON_PAYMENT_NOT_SUPPORTED"
        case threeRINotSupported = "THREE_RI_NOT_SUPPORTED"
        case acsTechnicalIssue = "ACS_TECHNICAL_ISSUE"
        case decoupledRequiredByACS = "DECOUPLED_REQUIRED_BY_ACS"
        case decoupledMaxExpiryExceeded = "DECOUPLED_MAX_EXPIRY_EXCEEDED"
        case decoupledAuthenticationInsufficientTime = "DECOUPLED_AUTHENTICATION_INSUFFICIENT_TIME"
        // swiftlint:disable:next identifier_name
        case authenticationAttemptedButNotPerformedByCardholder =
                "AUTHENTICATION_ATTEMPTED_BUT_NOT_PERFORMED_BY_CARDHOLDER"
        case acsTimedOut = "ACS_TIMED_OUT"
        case invalidACSResponse = "INVALID_ACS_RESPONSE"
        case acsSystemErrorResponse = "ACS_SYSTEM_ERROR_RESPONSE"
        case errorGeneratingCAVV = "ERROR_GENERATING_CAVV"
        case protocolVersionNotSupported = "PROTOCOL_VERSION_NOT_SUPPORTED"
        // swiftlint:disable:next identifier_name
        case transactionExcludedFromAttemptsProcessing = "TRANSACTION_EXCLUDED_FROM_ATTEMPTS_PROCESSING"
        case requestedProgramNotSupported = "REQUESTED_PROGRAM_NOT_SUPPORTED"
    }

    class ContinueInfo: Encodable {

        var platform: String
        var threeDsWrapperSdkVersion: String?
        var threeDsSdkProvider: String?
        var threeDsSdkVersion: String?
        var initProtocolVersion: String?
        var status: ThreeDS.Status
        var error: ThreeDS.ContinueInfo.Error?

        init(
            initProtocolVersion: String?,
            error: Primer3DSErrorContainer?
        ) {
            self.platform = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"
            self.initProtocolVersion = initProtocolVersion

            #if canImport(Primer3DS)
            self.threeDsWrapperSdkVersion = Primer3DS.version
            self.threeDsSdkProvider = Primer3DS.threeDsSdkProvider
            self.threeDsSdkVersion = Primer3DS.threeDsSdkVersion
            #endif

            if let primer3DSErr = error {
                self.status = .failure
                self.error = ThreeDS.ContinueInfo.Error(error: primer3DSErr)
            } else {
                self.status = .success
            }
        }

        // swiftlint:disable:next nesting
        class Error: Encodable {

            var reasonCode: String
            var reasonText: String
            var recoverySuggestion: String?
            var threeDsErrorDescription: String?
            var threeDsErrorCode: Int?
            var threeDsErrorComponent: String?
            var threeDsErrorDetail: String?
            var threeDsSdkTranscationId: String?
            var protocolVersion: String?

            init(error: Primer3DSErrorContainer) {
                self.reasonCode = error.errorId.uppercased().replacingOccurrences(of: "-", with: "_")
                self.reasonText = error.plainDescription
                self.recoverySuggestion = error.recoverySuggestion
                self.threeDsErrorDescription = error.threeDsErrorDescription
                self.threeDsErrorCode = error.threeDsErrorCode
                self.threeDsErrorComponent = error.threeDsErrorComponent
                self.threeDsErrorDetail = error.threeDsErrorDetail
                self.threeDsSdkTranscationId = error.threeDsSdkTranscationId
                self.protocolVersion = error.initProtocolVersion
            }
        }
    }
}
