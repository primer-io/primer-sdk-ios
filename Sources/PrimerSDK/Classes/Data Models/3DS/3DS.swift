//
//  3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 1/4/21.
//

import Foundation

protocol ThreeDSAuthenticationProtocol: Codable {
    var acsReferenceNumber: String? { get }
    var acsSignedContent: String? { get }
    var acsTransactionId: String? { get }
    var responseCode: ThreeDS.ResponseCode { get }
    var transactionId: String? { get }
}

public struct ThreeDS {

    internal struct ACSRenderingType: Codable {
        let acsInterface: String?
        let acsUiTemplate: String?
    }
    
    internal enum AuthenticationStatus: String {
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
    
    internal enum TestScenario: String, Codable {
        // swiftlint:disable identifier_name
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
        // swiftlint:enable identifier_name
    }
    
    internal struct BeginAuthRequest: Codable {
        
        static var demoAuthRequest: BeginAuthRequest {
            let threeDSecureBeginAuthRequest = BeginAuthRequest(testScenario: nil,
                                                                amount: 100,
                                                                currencyCode: .EUR,
                                                                orderId: "test_id",
                                                                customer: ThreeDS.Customer(name: "Evangelos",
                                                                                               email: "evangelos@primer.io",
                                                                                               homePhone: nil,
                                                                                               mobilePhone: nil,
                                                                                               workPhone: nil),
                                                                device: nil,
                                                                billingAddress: ThreeDS.Address(title: nil,
                                                                                                    firstName: nil,
                                                                                                    lastName: nil,
                                                                                                    email: nil,
                                                                                                    phoneNumber: nil,
                                                                                                    addressLine1: "my address line 1",
                                                                                                    addressLine2: nil,
                                                                                                    addressLine3: nil,
                                                                                                    city: "Athens",
                                                                                                    state: nil,
                                                                                                    countryCode: .gr,
                                                                                                    postalCode: "11472"),
                                                                shippingAddress: nil,
                                                                customerAccount: nil)
            return threeDSecureBeginAuthRequest
        }
        
        var testScenario: ThreeDS.TestScenario?
        var amount: Int
        let currencyCode: Currency
        let orderId: String
        let customer: ThreeDS.Customer
        var device: NetceteraAuthData?
        let billingAddress: ThreeDS.Address
        let shippingAddress: ThreeDS.Address?
        let customerAccount: ThreeDS.CustomerAccount?
    }
    
    internal struct NetceteraThreeDSCompletion {
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
        let addressLine1: String
        let addressLine2: String?
        let addressLine3: String?
        let city: String
        let state: String?
        let countryCode: CountryCode
        let postalCode: String
    }
    
    internal struct CustomerAccount: Codable {
        let id: String?
        let createdAt: String?
        let updatedAt: String?
        let passwordUpdatedAt: String?
        let purchaseCount: Int?
    }
    
    internal enum ResponseCode: String, Codable {
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
        struct Token: Codable {
            let token: String
            let analyticsId: String
            let tokenType: String
            let paymentInstrumentType: PaymentInstrumentType
            let paymentInstrumentData: PaymentInstrumentData
            let vaultData: VaultData?
            let threeDSecureAuthentication: AuthenticationDetails?
        }
        
        let authentication: ThreeDSAuthenticationProtocol
        let token: ThreeDS.BeginAuthResponse.Token
        
        enum CodingKeys: String, CodingKey {
            case authentication
            case token
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let threeDSDeclinedAPIResponse = (try? container.decode(ThreeDS.DeclinedAPIResponse.self, forKey: .authentication)) {
                authentication = threeDSDeclinedAPIResponse
            } else if let threeDSSkippedAPIResponse = try? container.decode(ThreeDS.SkippedAPIResponse.self, forKey: .authentication) {
                authentication = threeDSSkippedAPIResponse
            } else if let threeDSAppV2ChallengeAPIResponse = try? container.decode(ThreeDS.AppV2ChallengeAPIResponse.self, forKey: .authentication) {
                authentication = threeDSAppV2ChallengeAPIResponse
            }else if let threeDSBrowserV2ChallengeAPIResponse = try? container.decode(ThreeDS.BrowserV2ChallengeAPIResponse.self, forKey: .authentication) {
                authentication = threeDSBrowserV2ChallengeAPIResponse
            } else if let threeDSBrowserV1ChallengeAPIResponse = try? container.decode(ThreeDS.BrowserV1ChallengeAPIResponse.self, forKey: .authentication) {
                authentication = threeDSBrowserV1ChallengeAPIResponse
            } else if let threeDSSuccessAPIResponse = try? container.decode(Authentication.self, forKey: .authentication) {
                authentication = threeDSSuccessAPIResponse
            } else if let threeDSMethodAPIResponse = try? container.decode(ThreeDS.MethodAPIResponse.self, forKey: .authentication) {
                authentication = threeDSMethodAPIResponse
            }  else {
                let err = ThreeDSError.failedToParseResponse
                throw err
            }
            
            token = try container.decode(ThreeDS.BeginAuthResponse.Token.self, forKey: .token)
        }
    }
    
    internal struct PostAuthResponse: Codable {
        let token: PaymentMethodToken
        let resumeToken: String?
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
        let protocolVersion: String
        let xid: String?
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
        
        let protocolVersion: String
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
        
        let protocolVersion: String
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
        
        let protocolVersion: String
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
        
        let protocolVersion: String
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
        
        let protocolVersion: String
        let acsOperatorId: String?
        let acsReferenceNumber: String?
        let dsReferenceNumber: String?
        let dsTransactionId: String?
        let eci: String?
        let declinedReasonCode: ThreeDS.DeclinedReasonCode
        let declinedReasonText: String
    }
    
    public struct AuthenticationDetails: Codable {
        let responseCode: String
        let reasonCode, reasonText, protocolVersion: String?
        let challengeIssued: Bool?
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
        case authenticationAttemptedButNotPerformedByCardholder = "AUTHENTICATION_ATTEMPTED_BUT_NOT_PERFORMED_BY_CARDHOLDER"
        case acsTimedOut = "ACS_TIMED_OUT"
        case invalidACSResponse = "INVALID_ACS_RESPONSE"
        case acsSystemErrorResponse = "ACS_SYSTEM_ERROR_RESPONSE"
        case errorGeneratingCAVV = "ERROR_GENERATING_CAVV"
        case protocolVersionNotSupported = "PROTOCOL_VERSION_NOT_SUPPORTED"
        case transactionExcludedFromAttemptsProcessing = "TRANSACTION_EXCLUDED_FROM_ATTEMPTS_PROCESSING"
        case requestedProgramNotSupported = "REQUESTED_PROGRAM_NOT_SUPPORTED"
    }
}
