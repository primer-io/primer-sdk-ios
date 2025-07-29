//
//  PrimerRawOTPDataTokenizationBuilder.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length

import Foundation

final class PrimerRawOTPDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawOTPInput = self.rawData as? PrimerOTPData {
                rawOTPInput.onDataDidChange = { [weak self] in
                    guard let self = self else { return }
                    _ = self.validateRawData(rawOTPInput)
                }
            }

            if let rawData = self.rawData {
                _ = self.validateRawData(rawData)
            }
        }
    }

    weak var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    var isDataValid: Bool = false
    var paymentMethodType: String
    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?

    var requiredInputElementTypes: [PrimerInputElementType] {
        [.otp]
    }

    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in

            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
                return seal.reject(handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType)))
            }

            guard let rawData = data as? PrimerOTPData else {
                return seal.reject(handled(primerError: .invalidValue(key: "rawData")))
            }

            let sessionInfo = BlikSessionInfo(blikCode: rawData.otp, locale: PrimerSettings.current.localeData.localeCode)

            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: sessionInfo)

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization {
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
            throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
        }

        guard let rawData = data as? PrimerOTPData else {
            throw handled(primerError: .invalidValue(key: "rawData"))
        }

        return Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: BlikSessionInfo(
                    blikCode: rawData.otp,
                    locale: PrimerSettings.current.localeData.localeCode
                )
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerOTPData else {
                    let err = handled(error: PrimerValidationError.invalidRawData())
                    errors.append(err)
                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)
                    DispatchQueue.main.async { seal.reject(err) }
                    return
                }

                if !rawData.otp.isValidOTP {
                    errors.append(PrimerValidationError.invalidOTPCode(message: "OTP is not valid."))
                }

                if !errors.isEmpty {
                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(handled(primerError: .underlyingErrors(errors: errors)))
                    }
                } else {
                    self.notifyDelegateOfValidationResult(isValid: true, errors: nil)

                    DispatchQueue.main.async {
                        seal.fulfill()
                    }
                }
            }
        }
    }

    func validateRawData(_ data: PrimerRawData) async throws {
        var errors: [PrimerValidationError] = []

        guard let rawData = data as? PrimerOTPData else {
            let err = PrimerValidationError.invalidRawData()
            errors.append(err)
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw handled(error: err)
        }

        if !rawData.otp.isValidOTP {
            errors.append(PrimerValidationError.invalidOTPCode(message: "OTP is not valid."))
        }

        guard errors.isEmpty else {
            let err = PrimerError.underlyingErrors(errors: errors)
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw handled(primerError: err)
        }

        notifyDelegateOfValidationResult(isValid: true, errors: nil)
    }

    private func notifyDelegateOfValidationResult(isValid: Bool, errors: [Error]?) {
        isDataValid = isValid

        DispatchQueue.main.async { [weak self] in
            guard let self, let rawDataManager else { return }

            rawDataManager.delegate?.primerRawDataManager?(
                rawDataManager,
                dataIsValid: isValid,
                errors: errors
            )
        }
    }
}
// swiftlint:enable function_body_length
