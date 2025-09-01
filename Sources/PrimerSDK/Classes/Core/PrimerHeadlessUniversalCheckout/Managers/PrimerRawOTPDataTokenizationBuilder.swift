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
                    Task { try? await self.validateRawData(rawOTPInput) }
                }
            }

            if let rawData = self.rawData {
                Task { try? await self.validateRawData(rawData) }
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
