//
//  NolPayUnlink.swift
//  PrimerSDK
//
//  Created by Boris on 13.9.23..
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

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
    case cardAndPhoneData(nolPaymentCard: PrimerNolPaymentCard, mobileNumber: String)
    case otpData(otpCode: String)
}

public class NolPayUnlinkCardComponent: PrimerHeadlessCollectDataComponent {
    public typealias COLLECTABLE = NolPayUnlinkCollectableData
    public typealias STEPPABLE = NolPayUnlinkDataStep

    init() {
        self.phoneMetadataService = NolPayPhoneMetadataService()
    }

    #if canImport(PrimerNolPaySDK)
    private var nolPay: PrimerNolPay!
    #endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    var phoneMetadataService: NolPayPhoneMetadataProviding?

    public var mobileNumber: String?
    public var countryCode: String?
    public var otpCode: String?
    public var cardNumber: String?
    private var unlinkToken: String?
    public var nextDataStep: NolPayUnlinkDataStep = .collectCardAndPhoneData

    public func updateCollectedData(collectableData: COLLECTABLE) {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.unlinkCardUpdateCollectedDataMethod,
            params: [ "category": "NOL_PAY" ]
        )
        Analytics.Service.record(events: [sdkEvent])

        switch collectableData {

        case .cardAndPhoneData(nolPaymentCard: let nolPaymentCard,
                               mobileNumber: let mobileNumber):
            nextDataStep = .collectCardAndPhoneData
            cardNumber = nolPaymentCard.cardNumber
            self.mobileNumber = mobileNumber
        case .otpData(otpCode: let otpCode):
            nextDataStep = .collectOtpData
            self.otpCode = otpCode
        }

        validateData(for: collectableData)
    }

    public func validateData(for data: NolPayUnlinkCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        var errors: [PrimerValidationError] = []

        switch data {

        case .cardAndPhoneData(nolPaymentCard: let card, mobileNumber: let mobileNumber):

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

            phoneMetadataService?.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
                switch result {

                case let .success((validationStatus, countryCode, mobileNumber)):
                    switch validationStatus {

                    case .valid:
                        if errors.isEmpty {
                            self?.countryCode = countryCode
                            self?.mobileNumber = mobileNumber
                            self?.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
                        } else {
                            self?.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
                        }

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
                self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
            } else {
                self.validationDelegate?.didUpdate(validationStatus: .valid, for: data)

            }
        }
    }

    public func submit() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.unlinkCardSubmitDataMethod,
            params: [ "category": "NOL_PAY" ]
        )
        Analytics.Service.record(events: [sdkEvent])

        switch nextDataStep {

        case .collectCardAndPhoneData:
            guard let mobileNumber = mobileNumber
            else {
                makeAndHandleInvalidValueError(forKey: "mobileNumber")
                return
            }

            guard let countryCode = countryCode
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
                                 with: countryCode,
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
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.unlinkCardStartMethod,
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
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
