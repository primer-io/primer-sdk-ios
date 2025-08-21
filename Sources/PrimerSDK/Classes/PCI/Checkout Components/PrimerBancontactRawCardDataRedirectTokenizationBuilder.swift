//
//  PrimerBancontactRawCardDataRedirectTokenizationBuilder.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// swiftlint:disable type_name
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

// MARK: MISSING_TESTS
final class PrimerBancontactRawCardDataRedirectTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawCardData = self.rawData as? PrimerBancontactCardData {
                rawCardData.onDataDidChange = { [weak self] in
                    guard let self = self else { return }
                    _ = self.validateRawData(rawCardData)

                    let newCardNetwork = CardNetwork(cardNumber: rawCardData.cardNumber)
                    if newCardNetwork != self.cardNetwork {
                        self.cardNetwork = newCardNetwork
                    }
                }

                let newCardNetwork = CardNetwork(cardNumber: rawCardData.cardNumber)
                if newCardNetwork != self.cardNetwork {
                    self.cardNetwork = newCardNetwork
                }

            } else {
                if self.cardNetwork != .unknown {
                    self.cardNetwork = .unknown
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

    public private(set) var cardNetwork: CardNetwork = .unknown {
        didSet {
            guard let rawDataManager = rawDataManager else {
                return
            }

            DispatchQueue.main.async {
                rawDataManager.delegate?.primerRawDataManager?(rawDataManager, metadataDidChange: ["cardNetwork": self.cardNetwork.rawValue])
            }
        }
    }

    var requiredInputElementTypes: [PrimerInputElementType] {
        [.cardNumber, .expiryDate, .cardholderName]
    }

    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in

            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType),
                  let configId = AppState.current.apiConfiguration?.getConfigId(for: paymentMethod.type) else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let rawData = data as? PrimerCardData,
                  (rawData.expiryDate.split(separator: "/")).count == 2
            else {
                let err = PrimerError.invalidValue(key: "rawData")
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let expiryMonth = String((rawData.expiryDate.split(separator: "/"))[0])
            let expiryYear = String((rawData.expiryDate.split(separator: "/"))[1])

            let sanatizedCardNumber = (PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as? String) ?? rawData.cardNumber
            let paymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
                                                                    paymentMethodType: paymentMethodType,
                                                                    number: sanatizedCardNumber,
                                                                    expirationMonth: expiryMonth,
                                                                    expirationYear: expiryYear,
                                                                    cardholderName: rawData.cardholderName ?? "")

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization {
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType),
              let configId = AppState.current.apiConfiguration?.getConfigId(for: paymentMethod.type) else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let rawData = data as? PrimerCardData,
              (rawData.expiryDate.split(separator: "/")).count == 2 else {
            let err = PrimerError.invalidValue(key: "rawData")
            ErrorHandler.handle(error: err)
            throw err
        }

        let expiryMonth = String((rawData.expiryDate.split(separator: "/"))[0])
        let expiryYear = String((rawData.expiryDate.split(separator: "/"))[1])
        let sanitizedCardNumber = (PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as? String) ?? rawData.cardNumber

        return Request.Body.Tokenization(
            paymentInstrument: CardOffSessionPaymentInstrument(
                paymentMethodConfigId: configId,
                paymentMethodType: paymentMethodType,
                number: sanitizedCardNumber,
                expirationMonth: expiryMonth,
                expirationYear: expiryYear,
                cardholderName: rawData.cardholderName ?? ""
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerBancontactCardData else {
                    let err = handled(primerValidationError: .invalidRawData())
                    errors.append(err)
                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(err)
                    }

                    return
                }

                if rawData.cardNumber.isEmpty {
                    errors.append(PrimerValidationError.invalidCardnumber(message: "Card number can not be blank."))
                } else if !rawData.cardNumber.isValidCardNumber {
                    errors.append(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
                }

                do {
                    try rawData.expiryDate.validateExpiryDateString()
                } catch {
                    if let err = error as? PrimerValidationError {
                        errors.append(err)
                    }
                }

                if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
                    if rawData.cardholderName.isEmpty {
                        errors.append(
                            PrimerValidationError.invalidCardholderName(
                                message: "Cardholder name cannot be blank."
                            )
                        )

                    } else if !(rawData.cardholderName).isValidNonDecimalString {
                        errors.append(
                            PrimerValidationError.invalidCardholderName(
                                message: "Cardholder name is not valid."
                            )
                        )
                    }
                }

                if !errors.isEmpty {
                    let err = handled(primerError: .underlyingErrors(errors: errors))

                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(err)
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

        guard let rawData = data as? PrimerBancontactCardData else {
            let err = handled(primerValidationError: .invalidRawData())
            errors.append(err)
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw err
        }

        if rawData.cardNumber.isEmpty {
            errors.append(PrimerValidationError.invalidCardnumber(message: "Card number can not be blank."))
        } else if !rawData.cardNumber.isValidCardNumber {
            errors.append(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
        }

        do {
            try rawData.expiryDate.validateExpiryDateString()
        } catch {
            if let err = error as? PrimerValidationError {
                errors.append(err)
            }
        }

        if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
            if rawData.cardholderName.isEmpty {
                errors.append(PrimerValidationError.invalidCardholderName(
                    message: "Cardholder name cannot be blank."
                ))
            } else if !(rawData.cardholderName).isValidNonDecimalString {
                errors.append(PrimerValidationError.invalidCardholderName(
                    message: "Cardholder name is not valid."
                ))
            }
        }

        guard errors.isEmpty else {
            let err = PrimerError.underlyingErrors(errors: errors)
            ErrorHandler.handle(error: err)

            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw err
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
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
