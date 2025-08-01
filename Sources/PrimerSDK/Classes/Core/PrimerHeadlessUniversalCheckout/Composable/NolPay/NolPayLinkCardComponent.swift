//
//  NolPayLinkCardComponent.swift
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

public enum NolPayLinkCollectableData: PrimerCollectableData {
    case phoneData(mobileNumber: String)
    case otpData(otpCode: String)
}

public enum NolPayLinkCardStep: PrimerHeadlessStep {
    case collectPhoneData(cardNumber: String), collectOtpData(phoneNumber: String), collectTagData, cardLinked
}

public final class NolPayLinkCardComponent: PrimerHeadlessCollectDataComponent {
    public typealias COLLECTABLE = NolPayLinkCollectableData
    public typealias STEPPABLE = NolPayLinkCardStep

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
    public var linkToken: String?
    public var nextDataStep: NolPayLinkCardStep = .collectTagData

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
            name: NolPayAnalyticsConstants.linkCardUpdateCollectedDataMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.record(events: [sdkEvent])

        switch collectableData {
        case .phoneData(let mobileNumber):
            nextDataStep = .collectPhoneData(cardNumber: cardNumber ?? "")
            self.mobileNumber = mobileNumber
        case .otpData(let otpCode):
            nextDataStep = .collectOtpData(phoneNumber: mobileNumber ?? "")
            self.otpCode = otpCode
        }

        validateData(for: collectableData)
    }

    private func validateData(for data: NolPayLinkCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        var errors: [PrimerValidationError] = []

        switch data {
        case .phoneData(mobileNumber: let mobileNumber):
            phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success((let validationStatus, let countryCode, let mobileNumber)):
                    switch validationStatus {
                    case .valid:
                        self.countryCode = countryCode
                        self.mobileNumber = mobileNumber
                        self.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
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
                errors.append(handled(error: PrimerValidationError.invalidOTPCode( message: "OTP is not valid.")))
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        }
    }

    public func submit() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.linkCardSubmitDataMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.record(events: [sdkEvent])

        switch nextDataStep {
        case .collectPhoneData:
            guard let mobileNumber else {
                return makeAndHandleInvalidValueError(forKey: "mobileNumber")
            }

            guard let countryCode else {
                return makeAndHandleInvalidValueError(forKey: "countryCode")
            }

            guard let linkToken else {
                return makeAndHandleInvalidValueError(forKey: "linkToken")
            }

            #if canImport(PrimerNolPaySDK)

            guard let nolPay else {
                return makeAndHandleNolPayInitializationError()
            }

            nolPay.sendLinkOTP(to: mobileNumber,
                               with: countryCode,
                               and: linkToken) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .collectOtpData(phoneNumber: "\(countryCode) \(mobileNumber)")
                        self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                    } else {
                        self.errorDelegate?.didReceiveError(
                            error: handled(
                                primerError: .nolError(
                                    code: "unknown",
                                    message: "Sending of OTP SMS failed from unknown reason"
                                )
                            )
                        )
                    }
                case .failure(let error):
                    self.errorDelegate?.didReceiveError(
                        error: handled(
                            primerError: .nolError(
                                code: error.errorCode,
                                message: error.description
                            )
                        )
                    )
                }
            }
            #endif
        case .collectOtpData:
            guard let otpCode else {
                return makeAndHandleInvalidValueError(forKey: "otpCode")
            }

            guard let linkToken else {
                return makeAndHandleInvalidValueError(forKey: "linkToken")
            }

            #if canImport(PrimerNolPaySDK)

            guard let nolPay else {
                return makeAndHandleNolPayInitializationError()
            }

            nolPay.linkCard(for: otpCode,
                            and: linkToken) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let success):
                    if success {
                        self.nextDataStep = .cardLinked
                        self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                    } else {
                        self.errorDelegate?.didReceiveError(
                            error: handled(
                                primerError: .nolError(
                                    code: "unknown",
                                    message: "Linking of the card failed failed from unknown reason"
                                )
                            )
                        )
                    }
                case .failure(let error):
                    self.errorDelegate?.didReceiveError(
                        error: handled(
                            error: .nolError(
                                code: error.errorCode,
                                message: error.description
                            )
                        )
                    )
                }
            }
            #endif
        case .collectTagData:

            #if canImport(PrimerNolPaySDK)

            guard let nolPay else {
                return makeAndHandleNolPayInitializationError()
            }

            nolPay.scanNFCCard { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let cardNumber):
                    self.cardNumber = cardNumber
                    nolPay.makeLinkingToken(for: cardNumber) { result in
                        switch result {
                        case .success(let token):
                            self.linkToken = token
                            self.nextDataStep = .collectPhoneData(cardNumber: cardNumber)
                            self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                        case .failure(let error):
                            self.errorDelegate?.didReceiveError(
                                error: handled(
                                    primerError: .nolError(
                                        code: error.errorCode,
                                        message: error.description
                                    )
                                )
                            )
                        }
                    }

                case .failure(let error):
                    self.errorDelegate?.didReceiveError(
                        error: handled(
                            primerError: .nolError(
                                code: error.errorCode,
                                message: error.description
                            )
                        )
                    )
                }
            }
            #endif
        default: break
        }
    }

    public func start() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.linkCardStartMethod,
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
        let error = handled(primerError: .missingSDK(
            paymentMethodType: PrimerPaymentMethodType.nolPay.rawValue,
            sdkName: "PrimerNolPaySDK"
        ))
        errorDelegate?.didReceiveError(error: error)
        #endif
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
