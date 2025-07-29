//
//  PrimerRawPhoneNumberDataTokenizationBuilder.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable type_name

import Foundation

// MARK: MISSING_TESTS
final class PrimerRawPhoneNumberDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawPhoneNumberInput = self.rawData as? PrimerPhoneNumberData {
                rawPhoneNumberInput.onDataDidChange = { [weak self] in
                    guard let self = self else { return }
                    _ = self.validateRawData(rawPhoneNumberInput)
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
        [.phoneNumber]
    }

    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            guard
                let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType),
                let paymentMethodId = paymentMethod.id else {
                return seal.reject(handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType)))
            }

            guard let rawData = data as? PrimerPhoneNumberData else {
                return seal.reject(handled(primerError: .invalidValue(key: "rawData")))
            }

            let sessionInfo = InputPhonenumberSessionInfo(phoneNumber: rawData.phoneNumber)

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

        guard let rawData = data as? PrimerPhoneNumberData else {
            throw handled(primerError: .invalidValue(key: "rawData"))
        }

        return Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: InputPhonenumberSessionInfo(phoneNumber: rawData.phoneNumber)
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerPhoneNumberData else {
                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(handled(error: PrimerValidationError.invalidRawData()))
                    }

                    return
                }

                if let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodType),
                   !rawData.phoneNumber.isValidPhoneNumberForPaymentMethodType(paymentMethodType) {
                    errors.append(PrimerValidationError.invalidPhoneNumber(message: "Phone number is not valid."))
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

        guard let rawData = data as? PrimerPhoneNumberData else {
            let err = PrimerValidationError.invalidRawData()
            errors.append(err)
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw handled(error: err)
        }

        if let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType),
           !rawData.phoneNumber.isValidPhoneNumberForPaymentMethodType(paymentMethodType) {
            errors.append(PrimerValidationError.invalidPhoneNumber(message: "Phone number is not valid."))
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
// swiftlint:enable type_name
// swiftlint:enable function_body_length
