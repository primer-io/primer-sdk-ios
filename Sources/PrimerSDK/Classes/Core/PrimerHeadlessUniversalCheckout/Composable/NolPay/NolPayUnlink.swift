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
    case collectCardData
    case collectPhoneData
    case collectOtpData
    case cardUnlinked
}

public enum NolPayUnlinkCollectableData: PrimerCollectableData {
    case cardData(nolPaymentCard: PrimerNolPaymentCard)
    case phoneData(mobileNumber: String, phoneCountryDiallingCode: String)
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
    public weak var stepDelegate: PrimerHeadlessStepableDelegate?
    private var isDebug: Bool

    private var mobileNumber: String?
    private var phoneCountryDiallingCode: String?
    private var otpCode: String?
    private var cardNumber: String?
    private var unlinkToken: String?
    private var nextDataStep: NolPayUnlinkDataStep = .collectCardData
    
    public func updateCollectedData(data: NolPayUnlinkCollectableData) {
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.UNLINK_CARD_UPDATE_COLLECTED_DATA_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])
        
        switch data {
        case .cardData(nolPaymentCard: let nolPaymentCard):
            cardNumber = nolPaymentCard.cardNumber
        case .phoneData(mobileNumber: let mobileNumber, phoneCountryDiallingCode: let phoneCountryDiallingCode):
            self.mobileNumber = mobileNumber
            self.phoneCountryDiallingCode = phoneCountryDiallingCode
        case .otpData(otpCode: let otpCode):
            self.otpCode = otpCode
        }
        
        // Notify validation delegate after updating data
        let validations = validateData(for: data)
        validationDelegate?.didValidate(validations: validations, for: data)
    }
    
    private func validateData(for data: NolPayUnlinkCollectableData) -> [PrimerValidationError] {
        var errors: [PrimerValidationError] = []
        
        switch data {
            
        case .phoneData(mobileNumber: let mobileNumber,
                        phoneCountryDiallingCode: let phoneCountryDiallingCode):
            if mobileNumber.isValidMobilePhoneNumber {
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
            
            if phoneCountryDiallingCode.isValidCountryCode {
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
            if otpCode.isValidOTP {
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
        default:
            break
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
            
        case .collectCardData:
            nextDataStep = .collectPhoneData
            stepDelegate?.didReceiveStep(step: NolPayUnlinkDataStep.collectPhoneData)
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
            
            guard let cardNumber = cardNumber
            else {
                makeAndHandleInvalidValueError(forKey: "cardNumber")
                return
            }
            
#if canImport(PrimerNolPaySDK)
            nolPay.sendUnlinkOTPTo(mobileNumber: mobileNumber,
                                   withCountryCode: phoneCountryDiallingCode,
                                   andCardNumber: cardNumber) { result in
                switch result {
                    
                case .success((_, let token)):
                    self.unlinkToken = token
                    self.nextDataStep = .collectOtpData
                    self.stepDelegate?.didReceiveStep(step: NolPayUnlinkDataStep.collectOtpData)
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
            nolPay.unlinkCardWith(cardNumber: cardNumber, otp: otpCode, andUnlinkToken: unlinkToken) { result in
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .cardUnlinked
                        self.stepDelegate?.didReceiveStep(step: NolPayUnlinkDataStep.cardUnlinked)
                    } else {
                        let error = PrimerError.nolError(code: -1,
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
        
        let isSandbox = clientToken.env == "SANDBOX"
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
