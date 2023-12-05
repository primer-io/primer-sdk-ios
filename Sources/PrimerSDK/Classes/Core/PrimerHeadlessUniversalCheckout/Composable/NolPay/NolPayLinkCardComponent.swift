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
    case phoneData(mobileNumber: String)
    case otpData(otpCode: String)
}

public enum NolPayLinkCardStep: PrimerHeadlessStep {
    case collectPhoneData(cardNumber: String), collectOtpData(phoneNumber: String), collectTagData, cardLinked
}

public class NolPayLinkCardComponent: PrimerHeadlessCollectDataComponent {

    public typealias T = NolPayLinkCollectableData
    public typealias P = NolPayLinkCardStep
    
#if canImport(PrimerNolPaySDK)
    private var nolPay: PrimerNolPayProtocol!
#endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    var phoneMetadataService = NolPayPhoneMetadataService()

    public var mobileNumber: String?
    public var countryCode: String?
    public var otpCode: String?
    public var cardNumber: String?
    public var linkToken: String?
    public var nextDataStep: NolPayLinkCardStep = .collectTagData

    public func updateCollectedData(collectableData: T) {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.linkCardUpdateCollectedDataMethod,
            params: [ "category": "NOL_PAY" ]
        )
        Analytics.Service.record(events: [sdkEvent])

        switch collectableData {
        case .phoneData(let mobileNumber):
            nextDataStep = .collectPhoneData(cardNumber: self.cardNumber ?? "")
            self.mobileNumber = mobileNumber
        case .otpData(let otpCode):
            nextDataStep = .collectOtpData(phoneNumber: self.mobileNumber ?? "")
            self.otpCode = otpCode
        }

        validateData(for: collectableData)
    }

    func validateData(for data: NolPayLinkCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        var errors: [PrimerValidationError] = []

        switch data {

        case .phoneData(mobileNumber: let mobileNumber):
            phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
                switch result {

                case let .success((validationStatus, countryCode, mobileNumber)):
                    switch validationStatus {

                    case .valid:
                        self?.countryCode = countryCode
                        self?.mobileNumber = mobileNumber
                        self?.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
                    case .invalid(errors: let validationErrors):
                        errors += validationErrors
                        self?.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
                    default: break
                    }
                case .failure(let error):
                    self?.validationDelegate?.didUpdate(validationStatus: .error(error: error), for: data)
                }
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
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)

            }
        }
    }

    public func submit() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.linkCardSubmitDataMethod,
            params: [ "category": "NOL_PAY" ]
        )
        Analytics.Service.record(events: [sdkEvent])

        switch nextDataStep {

        case .collectPhoneData:
            guard let mobileNumber = mobileNumber
            else {
                makeAndHandleInvalidValueError(forKey: "mobileNumber")
                return
            }

            guard let countryCode = countryCode
            else {
                makeAndHandleInvalidValueError(forKey: "countryCode")
                return
            }

            guard let linkToken = linkToken
            else {
                makeAndHandleInvalidValueError(forKey: "linkToken")
                return
            }

#if canImport(PrimerNolPaySDK)
            nolPay.sendLinkOTP(to: mobileNumber,
                               with: countryCode,
                               and: linkToken) { result in
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .collectOtpData(phoneNumber: "\(countryCode) \(mobileNumber)")
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
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.linkCardStartMethod,
            params: [ "category": "NOL_PAY" ]
        )
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
        var isDebug = false
#if DEBUG
        isDebug =  PrimerLogging.shared.logger.logLevel == .debug
#endif

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
}
