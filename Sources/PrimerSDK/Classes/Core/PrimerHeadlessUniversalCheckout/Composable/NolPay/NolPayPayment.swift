//
//  NolPayPayment.swift
//  PrimerSDK
//
//  Created by Boris on 18.9.23..
//

import Foundation
import PrimerNolPaySDK

public enum NolPayStartPaymentCollectableData: PrimerCollectableData {
    case paymentData(cardNumber: String, mobileNumber: String, phoneCountryDiallingCode: String)
}

public enum NolPayStartPaymentStep: PrimerHeadlessStep {
    case collectStartPaymentData
    case finishedPayment
}

public class NolPayStartPaymentComponent: PrimerHeadlessCollectDataComponent {
    
    public typealias T = NolPayStartPaymentCollectableData
    
    private var nolPay: PrimerNolPay!
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessStepableDelegate?
    
    private var mobileNumber: String?
    private var phoneCountryDiallingCode: String?
    private var cardNumber: String?
    private var nextDataStep: NolPayStartPaymentStep = .collectStartPaymentData

    public func updateCollectedData(data: NolPayStartPaymentCollectableData) {
        switch data {
        case let .paymentData(cardNumber, mobileNumber, phoneCountryDiallingCode):
            self.cardNumber = cardNumber
            self.mobileNumber = mobileNumber
            self.phoneCountryDiallingCode = phoneCountryDiallingCode
        }
        
        // Notify validation delegate after updating data
        let validations = validateData(for: data)
        validationDelegate?.didValidate(validations: validations, for: data)
    }
    
    private func validateData(for data: NolPayStartPaymentCollectableData) -> [PrimerValidationError] {
        var errors: [PrimerValidationError] = []
        
        switch data {
            
        case .paymentData(cardNumber: let cardNumber,
                          mobileNumber: let mobileNumber,
                          phoneCountryDiallingCode: let phoneCountryDiallingCode):
            if cardNumber.isEmpty {
                errors.append(PrimerValidationError.invalidCardnumber(
                    message: "Card number is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
                ErrorHandler.handle(error: errors.last!)
            }
            
            if mobileNumber.isEmpty {
                errors.append(PrimerValidationError.invalidPhoneNumber(
                    message: "Mobile number is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
                ErrorHandler.handle(error: errors.last!)
            }
            
            if phoneCountryDiallingCode.isEmpty {
                errors.append(PrimerValidationError.invalidPhoneNumberCountryCode(
                    message: "Country code number is not valid.",
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
        switch nextDataStep {
        case .collectStartPaymentData:
            guard let cardNumber = cardNumber,
                  let mobileNumber = mobileNumber,
                  let phoneCountryDiallingCode = phoneCountryDiallingCode
            else {
                let error = PrimerError.generic(message: "Invalid data, make sure you updated all needed data fields with 'updateCollectedData:' function first",
                                                userInfo: [
                                                    "file": #file,
                                                    "class": "\(Self.self)",
                                                    "function": #function,
                                                    "line": "\(#line)"
                                                ],
                                                diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                self.errorDelegate?.didReceiveError(error: error)

                return
            }

            // TODO: Get transacton number for cardNumber, mobileNumber and phoneCountryDiallingCode
            nolPay.requestPaymentFor(cardNumber: cardNumber, andTransactionNumber: "") { result in
                switch result {
                    
                case .success(let success):
                    if success {
                        self.nextDataStep = .finishedPayment
                        self.stepDelegate?.didReceiveStep(step: NolPayStartPaymentStep.finishedPayment)
                    } else {
                        let error = PrimerError.nolError(code: -1,
                                                         message: "Payment failed from unknown reason",
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

        default:
            break
        }
    }
    
    public func start() {
        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.internalPaymentMethodType == .nolPay})?.options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            let error = PrimerError.generic(message: "Initialisation error, Nol AppId is not present",
                                            userInfo: [
                                                "file": #file,
                                                "class": "\(Self.self)",
                                                "function": #function,
                                                "line": "\(#line)"
                                            ],
                                            diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            self.errorDelegate?.didReceiveError(error: error)
            return
        }
        
        nolPay = PrimerNolPay(appId: appId, isDebug: true, isSandbox: true) { sdkId, deviceId in
            // Implement your API call here and return the fetched secret key
            //            Task {
            //               ... async await
            //                }
            return "f335565cce50459d82e5542de7f56426"
        }
        
        stepDelegate?.didReceiveStep(step: NolPayStartPaymentStep.collectStartPaymentData)
    }
}
