//
//  NolPayPaymentComponent.swift
//  PrimerSDK
//
//  Created by Boris on 18.9.23..
//

import Foundation
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public enum NolPayPaymentCollectableData: PrimerCollectableData {
    case paymentData(cardNumber: String, mobileNumber: String, phoneCountryDiallingCode: String)
}

public enum NolPayPaymentStep: PrimerHeadlessStep {
    case collectCardAndPhoneData
    case paymentRequested
}

public class NolPayPaymentComponent: PrimerHeadlessCollectDataComponent {
    
    public typealias T = NolPayPaymentCollectableData
    
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
    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol!
    
    var mobileNumber: String?
    var phoneCountryDiallingCode: String?
    var cardNumber: String?
    var nextDataStep: NolPayPaymentStep = .collectCardAndPhoneData

    public func updateCollectedData(collectableData: NolPayPaymentCollectableData) {
        switch collectableData {
        case let .paymentData(cardNumber, mobileNumber, phoneCountryDiallingCode):
            self.cardNumber = cardNumber
            self.mobileNumber = mobileNumber
            self.phoneCountryDiallingCode = phoneCountryDiallingCode
        }
        
        // Notify validation delegate after updating data
        let validations = validateData(for: collectableData)
        validationDelegate?.didValidate(validations: validations, for: collectableData)
    }
    
    func validateData(for data: NolPayPaymentCollectableData) -> [PrimerValidationError] {
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
            
            if !mobileNumber.isValidMobilePhoneNumber {
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
            
            if !phoneCountryDiallingCode.isValidCountryCode {
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
        case .collectCardAndPhoneData:
            guard let cardNumber = cardNumber
            else {
                makeAndHandleInvalidValueError(forKey: "cardNumber")
                return
            }
            
            guard  let mobileNumber = mobileNumber
            else {
                makeAndHandleInvalidValueError(forKey: "mobileNumber")
                return
            }
            
            guard let phoneCountryDiallingCode = phoneCountryDiallingCode
            else {
                makeAndHandleInvalidValueError(forKey: "phoneCountryDiallingCode")
                return
            }

            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == "NOL_PAY" }).first as? NolPayTokenizationViewModel else {
                return
            }
            self.tokenizationViewModel = paymentMethod
            paymentMethod.nolPayCardNumber = cardNumber
            paymentMethod.mobileNumber = mobileNumber
            paymentMethod.mobileCountryCode = phoneCountryDiallingCode
            
            paymentMethod.triggerAsyncAction = { (transactionNumber: String, completion: ((Result<Bool, Error>) -> Void)?)  in
    #if canImport(PrimerNolPaySDK)
                self.nolPay.requestPayment(for: cardNumber, and: transactionNumber) { result in
                    switch result {
    
                    case .success(let success):
                        if success {
                            self.nextDataStep = .paymentRequested
                            self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                            completion?(.success(true))
                        } else {
                            let error = PrimerError.nolError(code: "unknown",
                                                             message: "Payment failed from unknown reason",
                                                             userInfo: [
                                                                "file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"
                                                             ],
                                                             diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: error)
                            completion?(.failure(error))
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
                        completion?(.failure(error))
                    }
                }
    #endif
            }
            paymentMethod.start()
            
        default:
            break
        }
    }
    
    public func start() {
        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.internalPaymentMethodType == .nolPay})?.options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            makeAndHandleInvalidValueError(forKey: "Nol AppID")
            return
        }
        
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                        ErrorHandler.handle(error: error)
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
