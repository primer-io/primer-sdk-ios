//
//  NolPayUnlink.swift
//  PrimerSDK
//
//  Created by Boris on 13.9.23..
//

import Foundation
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public enum NolPayUnlinkDataStep: PrimerHeadlessStep {
    case collectCardAndPhoneData
    case collectOtpData
    case cardUnlinked
}

public enum NolPayUnlinkCollectableData: PrimerCollectableData {
    case cardAndPhoneData(nolPaymentCard: PrimerNolPaymentCard, mobileNumber: String, phoneCountryDiallingCode: String)
    case otpData(otpCode: String)
}

public class NolPayUnlinkCardComponent: PrimerHeadlessCollectDataComponent {
    public typealias T = NolPayUnlinkCollectableData

    init(isDebug: Bool) {
        self.isDebug = isDebug
    }

#if canImport(PrimerNolPaySDK)
    private var nolPay: PrimerNolPay!
#endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    private var isDebug: Bool

    public var mobileNumber: String?
    public var phoneCountryDiallingCode: String?
    public var otpCode: String?
    public var cardNumber: String?
    private var unlinkToken: String?
    public var nextDataStep: NolPayUnlinkDataStep = .collectCardAndPhoneData
    
    public func updateCollectedData(collectableData: NolPayUnlinkCollectableData) {
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.UNLINK_CARD_UPDATE_COLLECTED_DATA_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])
        
        switch collectableData {
        
        case .cardAndPhoneData(nolPaymentCard: let nolPaymentCard,
                               mobileNumber: let mobileNumber,
                               phoneCountryDiallingCode: let phoneCountryDiallingCode):
            
            cardNumber = nolPaymentCard.cardNumber
            self.mobileNumber = mobileNumber
            self.phoneCountryDiallingCode = phoneCountryDiallingCode

        case .otpData(otpCode: let otpCode):
            self.otpCode = otpCode
        }
        
        // Notify validation delegate after updating data
        let validations = validateData(for: collectableData)
        validationDelegate?.didValidate(validations: validations, for: collectableData)
    }
    
    public func validateData(for data: NolPayUnlinkCollectableData) -> [PrimerValidationError] {
        var errors: [PrimerValidationError] = []
        
        switch data {
            
        case .cardAndPhoneData(nolPaymentCard: let card, mobileNumber: let mobileNumber,
                        phoneCountryDiallingCode: let phoneCountryDiallingCode):
            
            if card.cardNumber.isEmpty || !card.cardNumber.isNumeric {
                errors.append(PrimerValidationError.invalidCardnumber(
                    message: "Invalid Nol card number",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ], diagnosticsId: UUID().uuidString))
            }
            
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
                name: NolPayAnalyticsConstants.UNLINK_CARD_SUBMIT_DATA_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])
        
        switch nextDataStep {
            
        case .collectCardAndPhoneData:
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
            
            guard let cardNumber = cardNumber
            else {
                makeAndHandleInvalidValueError(forKey: "cardNumber")
                return
            }
            
#if canImport(PrimerNolPaySDK)
            nolPay.sendUnlinkOTP(to: mobileNumber,
                                 with: phoneCountryDiallingCode,
                                 and: cardNumber) { result in
                switch result {
                    
                case .success((_, let token)):
                    self.unlinkToken = token
                    self.nextDataStep = .collectOtpData
                    self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
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
            
            guard let unlinkToken = unlinkToken
            else {
                makeAndHandleInvalidValueError(forKey: "unlinkToken")
                return
            }
            
            guard let cardNumber = cardNumber
            else {
                makeAndHandleInvalidValueError(forKey: "cardNumber")
                return
            }
            
#if canImport(PrimerNolPaySDK)
            nolPay.unlinkCard(with: cardNumber, otp: otpCode, and: unlinkToken) { result in
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .cardUnlinked
                        self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                    } else {
                        let error = PrimerError.nolError(code: "unknown",
                                                         message: "Unlinking failed from unknown reason",
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
        default:
            break
        }
    }
    
    public func start() {
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.UNLINK_CARD_START_METHOD,
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
