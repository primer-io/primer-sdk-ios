//
//  NolPayLink.swift
//  PrimerSDK
//
//  Created by Boris on 13.9.23..
//

import Foundation
import PrimerNolPaySDK

public enum NolPayLinkCollectableData: PrimerCollectableData {
    case phoneData(mobileNumber: String, phoneCountryDiallingCode: String)
    case otpData(otpCode: String)
}

public enum NolPayLinkDataStep: PrimerHeadlessStep {
    case collectPhoneData(cardNumber: String), collectOtpData, collectTagData, cardLinked
}

public class NolPayLinkCardComponent: PrimerHeadlessCollectDataComponent {
    
    public typealias T = NolPayLinkCollectableData
    
    private var nolPay: PrimerNolPay!
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessStepableDelegate?
    
    private var mobileNumber: String?
    private var phoneCountryDiallingCode: String?
    private var otpCode: String?
    private var cardNumber: String?
    private var linkToken: String?
    private var nextDataStep: NolPayLinkDataStep = .collectTagData
    
    public func updateCollectedData(data: NolPayLinkCollectableData) {
        switch data {
        case .phoneData(let mobileNumber, let phoneCountryDiallingCode):
            self.mobileNumber = mobileNumber
            self.phoneCountryDiallingCode = phoneCountryDiallingCode
        case .otpData(let otpCode):
            self.otpCode = otpCode
        }
        
        // Notify validation delegate after updating data
        let validations = validateData(for: data)
        validationDelegate?.didValidate(validations: validations, for: data)
    }
    
    private func validateData(for data: NolPayLinkCollectableData) -> [PrimerValidationError] {
        var errors: [PrimerValidationError] = []
        
        switch data {
        case .phoneData(let mobile, let phoneCountryDiallingCode):
            if mobile.isEmpty {
                errors.append(PrimerValidationError.invalidPhoneNumber(
                    message: "Phone number is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
            }
            
            if phoneCountryDiallingCode.isEmpty {
                errors.append(PrimerValidationError.invalidPhoneNumberCountryCode(
                    message: "Country code is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
                
            }
        case .otpData(let otp):
            if otp.isEmpty {
                //                errors.append(PrimerValidationError(errorId: "invalid-otp", description: "Invalid OTP"))
            }
        }
        
        return errors
    }
    
    public func submit() {
        
        switch nextDataStep {
            
        case .collectPhoneData:
            guard let mobileNumber = mobileNumber,
                  let phoneCountryDiallingCode = phoneCountryDiallingCode,
                  let linkToken = linkToken
            else {
                //                self.errorDelegate?.didReceiveError(error: error)
                return
            }
            nolPay.sendLinkOTPTo(mobileNumber: mobileNumber,
                                 withCountryCode: phoneCountryDiallingCode,
                                 andToken: linkToken) { result in
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .collectOtpData
                        self.stepDelegate?.didReceiveStep(step: NolPayLinkDataStep.collectOtpData)
                    } else {
                        //                        self.errorDelegate?.didReceiveError(error: error)
                    }
                case .failure(let error):
                    self.errorDelegate?.didReceiveError(error: error)
                }
            }
        case .collectOtpData:
            guard let otpCode = otpCode,
                  let linkToken = linkToken
            else {
                //                self.errorDelegate?.didReceiveError(error: error)
                return
            }
            
            nolPay.linkCardFor(otp: otpCode, andLinkToken: linkToken) { result in
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .cardLinked
                        self.stepDelegate?.didReceiveStep(step: NolPayLinkDataStep.cardLinked)
                    } else {
                        //                        self.errorDelegate?.didReceiveError(error: error)
                    }
                case .failure(let error):
                    self.errorDelegate?.didReceiveError(error: error)
                }
            }
        case .collectTagData:
            nolPay.scanNFCCard { result in
                switch result {
                    
                case .success(let cardNumber):
                    self.cardNumber = cardNumber
                    self.nolPay.makeLinkingTokenFor(cardNumber: cardNumber) { result in
                        switch result {
                            
                        case .success(let token):
                            self.linkToken = token
                            self.nextDataStep = .collectPhoneData(cardNumber: cardNumber)
                            self.stepDelegate?.didReceiveStep(step: NolPayLinkDataStep.collectPhoneData(cardNumber: cardNumber))
                        case .failure(let error):
                            self.errorDelegate?.didReceiveError(error: error)
                        }
                    }
                    
                case .failure(let error):
                    self.errorDelegate?.didReceiveError(error: error)
                }
            }
            
        default: break
        }
    }
    
    public func start() {
        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.internalPaymentMethodType == .nolPay})?.options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            self.errorDelegate?.didReceiveError(error: PrimerError.generic(message: "Initialisation error",
                                                                           userInfo: [
                                                                               "file": #file,
                                                                               "class": "\(Self.self)",
                                                                               "function": #function,
                                                                               "line": "\(#line)"
                                                                           ],
                                                                           diagnosticsId: UUID().uuidString))
            return
        }
        
        nolPay = PrimerNolPay(appId: appId, isDebug: true, isSandbox: true) { sdkId, deviceId in
            // Implement your API call here and return the fetched secret key
            //            Task {
            //               ... async await
            //                }
            return "f335565cce50459d82e5542de7f56426"
        }
    }
}
