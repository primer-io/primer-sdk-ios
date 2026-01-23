//
//  3DS.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length

import Foundation
import PrimerFoundation
#if canImport(Primer3DS)
import Primer3DS
#endif

public protocol ThreeDSAuthenticationProtocol: Codable {
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

public final class ThreeDS {

    #if canImport(Primer3DS)
    public final class Cer: Primer3DSCertificate {

        public var cardScheme: String
        public var encryptionKey: String
        public var rootCertificate: String

        public init(cardScheme: String, rootCertificate: String, encryptionKey: String) {
            self.cardScheme = cardScheme
            self.rootCertificate = rootCertificate
            self .encryptionKey = encryptionKey
        }
    }

    public final class ServerAuthData: Primer3DSServerAuthData {

        public var acsReferenceNumber: String?
        public var acsSignedContent: String?
        public var acsTransactionId: String?
        public var responseCode: String
        public var transactionId: String?

        public init(
            acsReferenceNumber: String?,
            acsSignedContent: String?,
            acsTransactionId: String?,
            responseCode: String,
            transactionId: String?
        ) {
            self.acsReferenceNumber = acsReferenceNumber
            self.acsSignedContent = acsSignedContent
            self.acsTransactionId = acsTransactionId
            self.responseCode = responseCode
            self.transactionId = transactionId
        }
    }
    #endif

    public struct Keys: Codable {
        public let threeDSecureIoCertificates: [ThreeDS.Certificate]?
        public let threeDsProviderCertificates: [ThreeDS.Certificate]?
        public let netceteraApiKey: String?
    }

    public struct Certificate: Codable {
        public let encryptionKey: String
        public let cardNetwork: String
        public let rootCertificate: String
    }

    struct ACSRenderingType: Codable {
        let acsInterface: String?
        let acsUiTemplate: String?
    }

    enum AuthenticationStatus: String {
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
    }

    public struct SDKAuthData: ThreeDSSDKAuthDataProtocol {
        var sdkAppId: String
        var sdkTransactionId: String
        var sdkTimeout: Int
        var sdkEncData: String
        var sdkEphemPubKey: String
        var sdkReferenceNumber: String
        
        public init(
            sdkAppId: String,
            sdkTransactionId: String,
            sdkTimeout: Int,
            sdkEncData: String,
            sdkEphemPubKey: String,
            sdkReferenceNumber: String
        ) {
            self.sdkAppId = sdkAppId
            self.sdkTransactionId = sdkTransactionId
            self.sdkTimeout = sdkTimeout
            self.sdkEncData = sdkEncData
            self.sdkEphemPubKey = sdkEphemPubKey
            self.sdkReferenceNumber = sdkReferenceNumber
        }
    }

    public struct BeginAuthRequest: Codable {
        let maxProtocolVersion: String
        let device: ThreeDS.SDKAuthData
        
        public init(maxProtocolVersion: String, device: ThreeDS.SDKAuthData) {
            self.maxProtocolVersion = maxProtocolVersion
            self.device = device
        }
    }

    public enum Status: String, Codable {
        case success = "SUCCESS"
        case failure = "FAILURE"
    }

    public enum ProtocolVersion: String, Codable {
        // swiftlint:disable identifier_name
        case v_2_1_0 = "2.1.0"
        case v_2_2_0 = "2.2.0"
        // swiftlint:enable identifier_name

        public init?(rawValue: String) {
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

    struct Address: Codable {

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

    public enum ResponseCode: String, Codable {

        case notPerformed = "NOT_PERFORMED"
        case skipped = "SKIPPED"
        case authSuccess = "AUTH_SUCCESS"
        case authFailed = "AUTH_FAILED"
        case challenge = "CHALLENGE"
        case METHOD = "METHOD"
    }

    enum SkippedCode: String, Codable {

        case gatewayUnavailable = "GATEWAY_UNAVAILABLE"
        case disabledByMerchant = "DISABLED_BY_MERCHANT"
        case notSupportedByIssuer = "NOT_SUPPORTED_BY_ISSUER"
        case failedToNegotiate = "FAILED_TO_NEGOTIATE"
        case unknownACSResponse = "UNKNOWN_ACS_RESPONSE"
        case threeDSServerError = "3DS_SERVER_ERROR"
        case acquirerNotConfigured = "ACQUIRER_NOT_CONFIGURED"
        case acquirerNotParticipating = "ACQUIRER_NOT_PARTICIPATING"

    }

    public struct Authentication: ThreeDSAuthenticationProtocol {
        public let acsReferenceNumber: String?
        public let acsSignedContent: String?
        public let acsTransactionId: String?
        public let responseCode: ThreeDS.ResponseCode
        public let transactionId: String?
        let acsOperatorId: String?
        let cryptogram: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let protocolVersion: String?
        let xid: String?
        
        public init(
            acsReferenceNumber: String?,
            acsSignedContent: String?,
            acsTransactionId: String?,
            responseCode: ThreeDS.ResponseCode,
            transactionId: String?,
            acsOperatorId: String?,
            cryptogram: String?,
            dsReferenceNumber: String?,
            dsTransactionId: String?,
            eci: String?,
            protocolVersion: String?,
            xid: String?
        ) {
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

    public struct SkippedAPIResponse: ThreeDSAuthenticationProtocol, Codable {

        public let acsReferenceNumber: String?
        public let acsSignedContent: String?
        public let acsTransactionId: String?
        public let responseCode: ThreeDS.ResponseCode
        public let transactionId: String?
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

    public struct MethodAPIResponse: ThreeDSAuthenticationProtocol {
        public let acsReferenceNumber: String?
        public let acsSignedContent: String?
        public let acsTransactionId: String?
        public let responseCode: ThreeDS.ResponseCode
        public let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let acsMethodUrl: String?
        let notificationUrl: String?
        let statusUrl: String?
    }

    public struct BrowserV2ChallengeAPIResponse: ThreeDSAuthenticationProtocol {
        public let acsReferenceNumber: String?
        public let acsSignedContent: String?
        public let acsTransactionId: String?
        public let responseCode: ThreeDS.ResponseCode
        public let transactionId: String?
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

    public struct AppV2ChallengeAPIResponse: ThreeDSAuthenticationProtocol {
        public let acsReferenceNumber: String?
        public let acsSignedContent: String?
        public let acsTransactionId: String?
        public let responseCode: ThreeDS.ResponseCode
        public let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String
        let eci: String?
        let acsRenderingType: String
        let acsChallengeMandated: String
        let statusUrl: String
    }

    public struct BrowserV1ChallengeAPIResponse: ThreeDSAuthenticationProtocol {
        let acsRefNumber: String?
        public let acsSignedContent: String?
        public let acsTransactionId: String?
        public let responseCode: ThreeDS.ResponseCode
        public let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        public let acsReferenceNumber: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let acsChallengeUrl: String
        let acsChallengeData: String
        let statusUrl: String
        let notificationUrl: String
        let challengeWindowSize: String
    }

   public struct DeclinedAPIResponse: ThreeDSAuthenticationProtocol {

        let acsRefNumber: String?
        public let acsSignedContent: String?
        public let acsTransactionId: String?
        public let responseCode: ThreeDS.ResponseCode
        public let transactionId: String?
        let protocolVersion: String?
        let acsOperatorId: String?
        public let acsReferenceNumber: String?
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

    enum DeclinedReasonCode: String, Codable {

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
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
