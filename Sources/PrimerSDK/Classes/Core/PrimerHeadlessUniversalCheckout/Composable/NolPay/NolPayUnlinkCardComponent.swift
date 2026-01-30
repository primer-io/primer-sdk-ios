//
//  NolPayUnlinkCardComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import PrimerCore
import PrimerFoundation
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
        Analytics.Service.fire(events: [sdkEvent])

        switch collectableData {
        case let .cardAndPhoneData(nolPaymentCard: nolPaymentCard, mobileNumber: mobileNumber):
            nextDataStep = .collectCardAndPhoneData
            cardNumber = nolPaymentCard.cardNumber
            self.mobileNumber = mobileNumber
        case let .otpData(otpCode: otpCode):
            nextDataStep = .collectOtpData
            self.otpCode = otpCode
        }

        validateData(for: collectableData)
    }

    private func validateData(for data: NolPayUnlinkCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        switch data {
        case let .cardAndPhoneData(nolPaymentCard: card, mobileNumber: mobileNumber):
			handleCardAndPhoneData(card: card, mobileNumber: mobileNumber, data: data)
        case let .otpData(otpCode: otpCode):
            if !otpCode.isValidOTP {
                let error = handled(error: PrimerValidationError.invalidOTPCode(message: "OTP is not valid."))
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [error]), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        }
    }

	private func handleCardAndPhoneData(
		card: PrimerNolPaymentCard,
		mobileNumber: String,
		data: PrimerCollectableData
	) {
		var errors: [PrimerValidationError] = []
		if card.cardNumber.isEmpty || !card.cardNumber.isNumeric {
			errors.append(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
		}

		phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
			guard let self else { return }
			switch result {
			case let .success((validationStatus, countryCode, mobileNumber)):
				switch validationStatus {
				case .valid:
					if errors.isEmpty {
						self.countryCode = countryCode
						self.mobileNumber = mobileNumber
						self.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
					} else {
						self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
					}
				case let .invalid(errors: validationErrors):
					errors += validationErrors
					self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
				default: break
				}
			case let .failure(error):
				self.validationDelegate?.didUpdate(validationStatus: .error(error: error), for: data)
			}
		}
	}

    public func submit() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.unlinkCardSubmitDataMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.fire(events: [sdkEvent])

        switch nextDataStep {
        case .collectCardAndPhoneData:
            guard let mobileNumber, let countryCode, let cardNumber else {
				let key = mobileNumber == nil ? "mobileNumber" : countryCode == nil ? "countryCode" : "cardNumber"
				return makeAndHandleInvalidValueError(forKey: key)
            }

            #if canImport(PrimerNolPaySDK)
			sendUnlinkOTP(mobileNumber: mobileNumber, countryCode: countryCode, cardNumber: cardNumber)
            #endif
        case .collectOtpData:
			guard let otpCode, let unlinkToken, let cardNumber else {
				let key = otpCode == nil ? "otpCode" : unlinkToken == nil ? "unlinkToken" : "cardNumber"
				return makeAndHandleInvalidValueError(forKey: key)
            }

            #if canImport(PrimerNolPaySDK)
			unlinkCard(cardNumber: cardNumber, otpCode: otpCode, unlinkToken: unlinkToken)
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
        Analytics.Service.fire(events: [sdkEvent])

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
                    case let .success(appSecret):
                        continuation.resume(returning: appSecret.sdkSecret)
                    case let .failure(error):
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
	
	#if canImport(PrimerNolPaySDK)
	private func sendUnlinkOTP(mobileNumber: String, countryCode: String, cardNumber: String) {
		guard let nolPay else { return makeAndHandleNolPayInitializationError() }
		nolPay.sendUnlinkOTP(to: mobileNumber, with: countryCode, and: cardNumber) { [weak self] result in
			guard let self else { return }
			switch result {
			case let .success((_, token)):
				unlinkToken = token
				nextDataStep = .collectOtpData
				stepDelegate?.didReceiveStep(step: self.nextDataStep)
			case let .failure(error):
				let error = handled(primerError: .nolError(code: error.errorCode, message: error.description))
				errorDelegate?.didReceiveError(error: error)
			}
		}
	}
	
	private func unlinkCard(cardNumber: String, otpCode: String, unlinkToken: String) {
		guard let nolPay else { return makeAndHandleNolPayInitializationError() }
		nolPay.unlinkCard(with: cardNumber, otp: otpCode, and: unlinkToken) { [weak self] result in
			guard let self else { return }
			switch result {
			case let .success(success):
				if success {
					nextDataStep = .cardUnlinked
					stepDelegate?.didReceiveStep(step: nextDataStep)
				} else {
					let error = handled(primerError: .nolError(code: "unknown", message: "Unlinking failed from unknown reason"))
					errorDelegate?.didReceiveError(error: error)
				}
			case let .failure(error):
				let error = handled(primerError: .nolError(code: error.errorCode, message: error.description))
				errorDelegate?.didReceiveError(error: error)
			}
		}
	}
	#endif
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
