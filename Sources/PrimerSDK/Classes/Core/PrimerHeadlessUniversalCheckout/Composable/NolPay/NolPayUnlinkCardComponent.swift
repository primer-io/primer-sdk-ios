//
//  NolPayUnlinkCardComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import UIKit
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

public final class NolPayUnlinkCardComponent: PrimerHeadlessCollectDataComponent {
    public typealias COLLECTABLE = NolPayUnlinkCollectableData
    public typealias STEPPABLE = NolPayUnlinkDataStep

    #if canImport(PrimerNolPaySDK)
    var nolPay: PrimerNolPayProtocol?
    #endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?

    public var mobileNumber: String?
    public var countryCode: String?
    public var otpCode: String?
    public var cardNumber: String?
    public var unlinkToken: String?
    public var nextDataStep: NolPayUnlinkDataStep = .collectCardAndPhoneData

    private let apiClient: PrimerAPIClientProtocol
    private let phoneMetadataService: NolPayPhoneMetadataServiceProtocol

    public convenience init() {
        self.init(apiClient: PrimerAPIClient(), phoneMetadataService: NolPayPhoneMetadataService())
    }

    init(apiClient: PrimerAPIClientProtocol, phoneMetadataService: NolPayPhoneMetadataServiceProtocol) {
        self.apiClient = apiClient
        self.phoneMetadataService = phoneMetadataService
    }

    public func updateCollectedData(collectableData: COLLECTABLE) {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.unlinkCardUpdateCollectedDataMethod,
            params: ["category": "NOL_PAY"]
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

    private func validateData(for data: NolPayUnlinkCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        var errors: [PrimerValidationError] = []

        switch data {
        case .cardAndPhoneData(nolPaymentCard: let card, mobileNumber: let mobileNumber):

            if card.cardNumber.isEmpty || !card.cardNumber.isNumeric {
                errors.append(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
            }

            phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success((let validationStatus, let countryCode, let mobileNumber)):
                    switch validationStatus {
                    case .valid:
                        if errors.isEmpty {
                            self.countryCode = countryCode
                            self.mobileNumber = mobileNumber
                            self.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
                        } else {
                            self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
                        }

                    case .invalid(errors: let validationErrors):
                        errors += validationErrors
                        self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)

                    default: break
                    }
                case .failure(let error):
                    self.validationDelegate?.didUpdate(validationStatus: .error(error: error), for: data)
                }
            }
        case .otpData(otpCode: let otpCode):
            if !otpCode.isValidOTP {
                errors.append(handled(error: PrimerValidationError.invalidOTPCode(message: "OTP is not valid.")))
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        }
    }

    public func submit() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.unlinkCardSubmitDataMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.record(events: [sdkEvent])

        switch nextDataStep {
        case .collectCardAndPhoneData:
            guard let mobileNumber else {
                return makeAndHandleInvalidValueError(forKey: "mobileNumber")
            }

            guard let countryCode else {
                return makeAndHandleInvalidValueError(forKey: "countryCode")
            }

            guard let cardNumber else {
                return makeAndHandleInvalidValueError(forKey: "cardNumber")
            }

            #if canImport(PrimerNolPaySDK)

            guard let nolPay else {
                return makeAndHandleNolPayInitializationError()
            }

            nolPay.sendUnlinkOTP(to: mobileNumber,
                                 with: countryCode,
                                 and: cardNumber) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success((_, let token)):
                    self.unlinkToken = token
                    self.nextDataStep = .collectOtpData
                    self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                case .failure(let error):
                    let error = handled(primerError: .nolError(code: error.errorCode, message: error.description))
                    self.errorDelegate?.didReceiveError(error: error)
                }
            }
            #endif
        case .collectOtpData:
            guard let otpCode else {
                return makeAndHandleInvalidValueError(forKey: "otpCode")
            }

            guard let unlinkToken else {
                return makeAndHandleInvalidValueError(forKey: "unlinkToken")
            }

            guard let cardNumber else {
                return makeAndHandleInvalidValueError(forKey: "cardNumber")
            }

            #if canImport(PrimerNolPaySDK)

            guard let nolPay else {
                return makeAndHandleNolPayInitializationError()
            }

            nolPay.unlinkCard(with: cardNumber, otp: otpCode, and: unlinkToken) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .cardUnlinked
                        self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                    } else {
                        let error = handled(primerError: .nolError(code: "unknown", message: "Unlinking failed from unknown reason"))
                        self.errorDelegate?.didReceiveError(error: error)
                    }
                case .failure(let error):
                    let error = handled(primerError: .nolError(code: error.errorCode, message: error.description))
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
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.record(events: [sdkEvent])

        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?
                .first(where: { $0.internalPaymentMethodType == .nolPay })?
                .options as? MerchantOptions,
              let nolPayAppId = nolPaymentMethodOption.appId
        else {
            return makeAndHandleInvalidValueError(forKey: "nolPayAppId")
        }

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            errorDelegate?.didReceiveError(error: handled(primerError: .invalidClientToken()))
            return
        }

        let isSandbox = clientToken.env != "PRODUCTION"
        var isDebug = false
        #if DEBUG
        isDebug = PrimerLogging.shared.logger.logLevel == .debug
        #endif

        #if canImport(PrimerNolPaySDK)
        nolPay = PrimerNolPay(appId: nolPayAppId, isDebug: isDebug, isSandbox: isSandbox) { sdkId, deviceId in

            let requestBody = await Request.Body.NolPay.NolPaySecretDataRequest(nolSdkId: deviceId,
                                                                                nolAppId: sdkId,
                                                                                phoneVendor: "Apple",
                                                                                phoneModel: UIDevice.modelIdentifier!)

            return try await withCheckedThrowingContinuation { continuation in
                self.apiClient.fetchNolSdkSecret(clientToken: clientToken, paymentRequestBody: requestBody) { result in
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
        errorDelegate?.didReceiveError(
            error: handled(
                primerError: .missingSDK(
                    paymentMethodType: PrimerPaymentMethodType.nolPay.rawValue,
                    sdkName: "PrimerNolPaySDK"
                )
            )
        )
        #endif
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
