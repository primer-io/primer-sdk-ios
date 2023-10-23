//
//  NolPayLink.swift
//  PrimerSDK
//
//  Created by Boris on 13.9.23..
//

import Foundation
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public enum NolPayLinkCollectableData: PrimerCollectableData {
    case phoneData(mobileNumber: String, phoneCountryDiallingCode: String)
    case otpData(otpCode: String)
}

public enum NolPayLinkCardStep: PrimerHeadlessStep {
    case collectPhoneData(cardNumber: String), collectOtpData(phoneNumber: String), collectTagData, cardLinked
}

public class NolPayLinkCardComponent: PrimerHeadlessCollectDataComponent {
    
    public typealias T = NolPayLinkCollectableData
    
    init(isDebug: Bool) {
        self.isDebug = isDebug
    }
#if canImport(PrimerNolPaySDK)
    private var nolPay: PrimerNolPayProtocol!
#endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    private var isDebug: Bool
    
    public var mobileNumber: String?
    public var phoneCountryDiallingCode: String?
    public var otpCode: String?
    public var cardNumber: String?
    public var linkToken: String?
    public var nextDataStep: NolPayLinkCardStep = .collectTagData
    
    public func updateCollectedData(collectableData: NolPayLinkCollectableData) {
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINK_CARD_UPDATE_COLLECTED_DATA_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])

        switch collectableData {
        case .phoneData(let mobileNumber, let phoneCountryDiallingCode):
            self.mobileNumber = mobileNumber
            self.phoneCountryDiallingCode = phoneCountryDiallingCode
        case .otpData(let otpCode):
            self.otpCode = otpCode
        }
        
        // Notify validation delegate after updating data
        let validations = validateData(for: collectableData)
        validationDelegate?.didValidate(validations: validations, for: collectableData)
    }
    
    func validateData(for data: NolPayLinkCollectableData) -> [PrimerValidationError] {
        var errors: [PrimerValidationError] = []
        
        switch data {
            
        case .phoneData(mobileNumber: let mobileNumber,
                        phoneCountryDiallingCode: let phoneCountryDiallingCode):
            if !mobileNumber.isValidMobilePhoneNumber {
                errors.append(PrimerValidationError.invalidPhoneNumber(
                    message: "Phone number is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
                ErrorHandler.handle(error: errors.last!)
            }
            
            if !phoneCountryDiallingCode.isValidCountryCode {
                errors.append(PrimerValidationError.invalidPhoneNumberCountryCode(
                    message: "Country code is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
                ErrorHandler.handle(error: errors.last!)
                
            }
        case .otpData(otpCode: let otpCode):
            if !otpCode.isValidOTP {
                errors.append(PrimerValidationError.invalidOTPCode(
                    message: "OTP is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
                ErrorHandler.handle(error: errors.last!)
            }
        }
        
        return errors
    }
    
    public func submit() {
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINK_CARD_SUBMIT_DATA_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])

        switch nextDataStep {
            
        case .collectPhoneData:
            guard let mobileNumber = mobileNumber 
            else {
                makeAndHandleInvalidValueError(forKey: "mobileNumber")
                return
            }
            guard let phoneCountryDiallingCode = phoneCountryDiallingCode 
            else {
                makeAndHandleInvalidValueError(forKey: "phoneCountryDiallingCode")
                return
            }
            guard let linkToken = linkToken
            else {
                makeAndHandleInvalidValueError(forKey: "linkToken")
                return
            }
            
#if canImport(PrimerNolPaySDK)
            nolPay.sendLinkOTP(to: mobileNumber,
                               with: phoneCountryDiallingCode,
                               and: linkToken) { result in
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .collectOtpData(phoneNumber: "\(phoneCountryDiallingCode) \(mobileNumber)")
                        self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                    } else {
                        let error = PrimerError.nolError(code: "unknown",
                                                         message: "Sending of OTP SMS failed from unknown reason",
                                                         userInfo: [
                                                            "file": #file,
                                                            "class": "\(Self.self)",
                                                            "function": #function,
                                                            "line": "\(#line)"
                                                         ],
                                                         diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
                        self.errorDelegate?.didReceiveError(error: error)
                    }
                case .failure(let error):
                    let error = PrimerError.nolError(code: error.errorCode,
                                                     message: error.description,
                                                     userInfo: [
                                                        "file": #file,
                                                        "class": "\(Self.self)",
                                                        "function": #function,
                                                        "line": "\(#line)"
                                                     ],
                                                     diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: error)
                    self.errorDelegate?.didReceiveError(error: error)

                }
            }
            #endif
        case .collectOtpData:
            guard let otpCode = otpCode
            else {
                makeAndHandleInvalidValueError(forKey: "otpCode")
                return
            }
            
            guard  let linkToken = linkToken
            else {
                makeAndHandleInvalidValueError(forKey: "linkToken")
                return
            }
            
#if canImport(PrimerNolPaySDK)
            nolPay.linkCard(for: otpCode, and: linkToken) { result in
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .cardLinked
                        self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                    } else {
                        let error = PrimerError.nolError(code: "unknown",
                                                         message: "Linking of the card failed failed from unknown reason",
                                                         userInfo: [
                                                            "file": #file,
                                                            "class": "\(Self.self)",
                                                            "function": #function,
                                                            "line": "\(#line)"
                                                         ],
                                                         diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
                        self.errorDelegate?.didReceiveError(error: error)
                    }
                case .failure(let error):
                    let error = PrimerError.nolError(code: error.errorCode,
                                                     message: error.description,
                                                     userInfo: [
                                                        "file": #file,
                                                        "class": "\(Self.self)",
                                                        "function": #function,
                                                        "line": "\(#line)"
                                                     ],
                                                     diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: error)
                    self.errorDelegate?.didReceiveError(error: error)
                }
            }
#endif
        case .collectTagData:
#if canImport(PrimerNolPaySDK)
            nolPay.scanNFCCard { result in
                switch result {
                    
                case .success(let cardNumber):
                    self.cardNumber = cardNumber
                    self.nolPay.makeLinkingToken(for: cardNumber) { result in
                        switch result {
                            
                        case .success(let token):
                            self.linkToken = token
                            self.nextDataStep = .collectPhoneData(cardNumber: cardNumber)
                            self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                        case .failure(let error):
                            let primerError = PrimerError.nolError(code: error.errorCode,
                                                             message: error.description,
                                                             userInfo: [
                                                                "file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"
                                                             ],
                                                             diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: primerError)
                            self.errorDelegate?.didReceiveError(error: primerError)
                        }
                    }
                    
                case .failure(let error):
                    let error = PrimerError.nolError(code: error.errorCode,
                                                     message: error.description,
                                                     userInfo: [
                                                        "file": #file,
                                                        "class": "\(Self.self)",
                                                        "function": #function,
                                                        "line": "\(#line)"
                                                     ],
                                                     diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: error)
                    self.errorDelegate?.didReceiveError(error: error)
                }
            }
#endif
            
        default: break
        }
    }
    
    public func start() {
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINK_CARD_START_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])

        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.internalPaymentMethodType == .nolPay})?.options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            makeAndHandleInvalidValueError(forKey: "Nol AppID")
            return
        }
        
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, 
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"],
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return
        }
        
        let isSandbox = clientToken.env != "PRODUCTION"
#if canImport(PrimerNolPaySDK)
        nolPay = PrimerNolPay(appId: appId, isDebug: isDebug, isSandbox: isSandbox) { sdkId, deviceId in
            
            let requestBody = await Request.Body.NolPay.NolPaySecretDataRequest(nolSdkId: deviceId, 
                                                                                nolAppId: sdkId,
                                                                                phoneVendor: "Apple",
                                                                                phoneModel: UIDevice.modelIdentifier!)
            let client = PrimerAPIClient()
            if #available(iOS 13, *) {
                return try await withCheckedThrowingContinuation { continuation in
                    client.fetchNolSdkSecret(clientToken: clientToken, paymentRequestBody: requestBody) { result in
                        switch result {
                        case .success(let appSecret):
                            continuation.resume(returning: appSecret.sdkSecret)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } else {
                assertionFailure("Nol pay SDK requires iOS 13")
                return ""
            }
        }
#else
        let error = PrimerError.missingSDK(
            paymentMethodType: PrimerPaymentMethodType.nolPay.rawValue,
            sdkName: "PrimerNolPaySDK",
            userInfo: ["file": #file,
                       "class": "\(Self.self)",
                       "function": #function,
                       "line": "\(#line)"],
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        errorDelegate?.didReceiveError(error: error)
#endif
    }
    
    // Helper method
    private func makeAndHandleInvalidValueError(forKey key: String) {
        let error = PrimerError.invalidValue(key: key, value: nil, userInfo: [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ],
        diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        self.errorDelegate?.didReceiveError(error: error)
    }
}
