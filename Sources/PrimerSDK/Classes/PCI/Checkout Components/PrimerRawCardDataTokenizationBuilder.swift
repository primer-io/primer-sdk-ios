//
//  PrimerRawCardDataTokenizationBuilder.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable file_length

import Foundation

// MARK: MISSING_TESTS
final class PrimerRawCardDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawCardData = self.rawData as? PrimerCardData {
                rawCardData.onDataDidChange = { [weak self] in
                    guard let self else { return }
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

    var cardValidationService: CardValidationService?

    var isDataValid: Bool = false
    var paymentMethodType: String

    public private(set) var cardNetwork: CardNetwork = .unknown {
        didSet {
            guard let rawDataManager = rawDataManager else {
                return
            }

            DispatchQueue.main.async {
                rawDataManager.delegate?.primerRawDataManager?(rawDataManager,
                                                               metadataDidChange: ["cardNetwork": self.cardNetwork.rawValue])
            }
        }
    }

    /// List of supported card networks taken from merchant configuration
    var allowedCardNetworks: Set<CardNetwork> {
        Set(Array.allowedCardNetworks)
    }

    var requiredInputElementTypes: [PrimerInputElementType] {

        var mutableRequiredInputElementTypes: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]

        let cardInfoOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
            .first { $0.type == "CARD_INFORMATION" }?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions

        // swiftlint:disable:next identifier_name
        if let isCardHolderNameCheckoutModuleOptionEnabled = cardInfoOptions?.cardHolderName {
            if isCardHolderNameCheckoutModuleOptionEnabled {
                mutableRequiredInputElementTypes.append(.cardholderName)
            }
        } else {
            mutableRequiredInputElementTypes.append(.cardholderName)
        }

        return mutableRequiredInputElementTypes
    }

    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
        self.cardValidationService = DefaultCardValidationService(rawDataManager: rawDataManager)
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            guard PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) != nil
            else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let rawData = data as? PrimerCardData,
                  (rawData.expiryDate.split(separator: "/")).count == 2
            else {
                let err = PrimerError.invalidValue(key: "rawData",
                                                   value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let expiryMonth = String((rawData.expiryDate.split(separator: "/"))[0])
            let rawExpiryYear = String((rawData.expiryDate.split(separator: "/"))[1])

            guard let expiryYear = rawExpiryYear.normalizedFourDigitYear() else {
                return seal.reject(handled(primerValidationError: .invalidExpiryDate(
                    message: "Expiry year '\(rawExpiryYear)' is not valid. Please provide a 2-digit (YY) or 4-digit (YYYY) year."
                )))
            }

            let paymentInstrument = CardPaymentInstrument(
                number: (PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as? String) ?? rawData.cardNumber,
                cvv: rawData.cvv,
                expirationMonth: expiryMonth,
                expirationYear: expiryYear,
                cardholderName: rawData.cardholderName,
                preferredNetwork: rawData.cardNetwork?.rawValue
            )

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization {
        guard PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) != nil else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let rawData = data as? PrimerCardData,
              (rawData.expiryDate.split(separator: "/")).count == 2 else {
            let err = PrimerError.invalidValue(key: "rawData",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let expiryMonth = String((rawData.expiryDate.split(separator: "/"))[0])
        let rawExpiryYear = String((rawData.expiryDate.split(separator: "/"))[1])

        guard let expiryYear = rawExpiryYear.normalizedFourDigitYear() else {
            throw handled(primerValidationError: .invalidExpiryDate(
                message: "Expiry year '\(rawExpiryYear)' is not valid. Please provide a 2-digit (YY) or 4-digit (YYYY) year."
            ))
        }

        return Request.Body.Tokenization(
            paymentInstrument: CardPaymentInstrument(
                number: (PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as? String) ?? rawData.cardNumber,
                cvv: rawData.cvv,
                expirationMonth: expiryMonth,
                expirationYear: expiryYear,
                cardholderName: rawData.cardholderName,
                preferredNetwork: rawData.cardNetwork?.rawValue
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        validateRawData(data, cardNetworksMetadata: nil)
    }

    func validateRawData(_ data: PrimerRawData) async throws {
        try await validateRawData(data, cardNetworksMetadata: nil)
    }

    func validateRawData(_ data: PrimerRawData, cardNetworksMetadata: PrimerCardNumberEntryMetadata?) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self else {
                    // If self is deallocated, reject the promise gracefully
                    DispatchQueue.main.async {
                        let err = PrimerError.unknown(
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString
                        )
                        seal.reject(err)
                    }
                    return
                }

                var errors: [PrimerValidationError] = []

                // Invalid raw data error
                guard let rawData = data as? PrimerCardData else {
                    let err = PrimerValidationError.invalidRawData(
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)

                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(err)
                    }

                    return
                }

                // Locally validated card network
                var cardNetwork = CardNetwork(cardNumber: rawData.cardNumber)

                // Remotely validated card network
                if let cardNetworksMetadata = cardNetworksMetadata {
                    let didDetectNetwork = !cardNetworksMetadata.detectedCardNetworks.items.isEmpty &&
                        cardNetworksMetadata.detectedCardNetworks.items.map { $0.network } != [.unknown]

                    if didDetectNetwork && cardNetworksMetadata.detectedCardNetworks.preferred == nil,
                       let network = cardNetworksMetadata.detectedCardNetworks.items.first?.network {
                        cardNetwork = network
                    } else {
                        return
                    }

                    // Unsupported card type error
                    if !self.allowedCardNetworks.contains(cardNetwork) {
                        let err = PrimerValidationError.invalidCardType(
                            message: "Unsupported card type detected: \(cardNetwork.displayName)",
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString
                        )
                        errors.append(err)
                    }
                } else {
                    self.cardValidationService?.validateCardNetworks(withCardNumber: rawData.cardNumber)
                }

                // Invalid card number error
                if rawData.cardNumber.isEmpty {
                    let err = PrimerValidationError.invalidCardnumber(
                        message: "Card number can not be blank.",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                } else if !rawData.cardNumber.isValidCardNumber {
                    let err = PrimerValidationError.invalidCardnumber(
                        message: "Card number is not valid.",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                }

                // Invalid expiry error
                do {
                    try rawData.expiryDate.validateExpiryDateString()
                } catch {
                    if let err = error as? PrimerValidationError {
                        errors.append(err)
                    }
                }

                // Invalid cvv error
                if rawData.cvv.isEmpty {
                    let err = PrimerValidationError.invalidCvv(
                        message: "CVV cannot be blank.",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                } else if !rawData.cvv.isValidCVV(cardNetwork: cardNetwork) {
                    let err = PrimerValidationError.invalidCvv(
                        message: "CVV is not valid.",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                }

                // Cardholder name error
                if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
                    if (rawData.cardholderName ?? "").isEmpty {
                        errors.append(PrimerValidationError.invalidCardholderName(
                                        message: "Cardholder name cannot be blank.",
                                        userInfo: .errorUserInfoDictionary(),
                                        diagnosticsId: UUID().uuidString))
                    } else if !(rawData.cardholderName ?? "").isValidNonDecimalString {
                        errors.append(PrimerValidationError.invalidCardholderName(
                                        message: "Cardholder name is not valid.",
                                        userInfo: .errorUserInfoDictionary(),
                                        diagnosticsId: UUID().uuidString))
                    }
                }

                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(
                        errors: errors,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)

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

    func validateRawData(_ data: PrimerRawData, cardNetworksMetadata: PrimerCardNumberEntryMetadata?) async throws {
        var errors: [PrimerValidationError] = []

        guard let rawData = data as? PrimerCardData else {
            let err = PrimerValidationError.invalidRawData(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            errors.append(err)
            ErrorHandler.handle(error: err)

            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw err
        }

        // Locally validated card network
        var cardNetwork = CardNetwork(cardNumber: rawData.cardNumber)

        // Remotely validated card network
        if let cardNetworksMetadata = cardNetworksMetadata {
            let didDetectNetwork = !cardNetworksMetadata.detectedCardNetworks.items.isEmpty &&
                cardNetworksMetadata.detectedCardNetworks.items.map { $0.network } != [.unknown]

            if didDetectNetwork && cardNetworksMetadata.detectedCardNetworks.preferred == nil,
               let network = cardNetworksMetadata.detectedCardNetworks.items.first?.network {
                cardNetwork = network
            } else {
                return
            }

            // Unsupported card type error
            if !self.allowedCardNetworks.contains(cardNetwork) {
                let err = PrimerValidationError.invalidCardType(
                    message: "Unsupported card type detected: \(cardNetwork.displayName)",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                errors.append(err)
            }
        } else {
            self.cardValidationService?.validateCardNetworks(withCardNumber: rawData.cardNumber)
        }

        // Invalid card number error
        if rawData.cardNumber.isEmpty {
            let err = PrimerValidationError.invalidCardnumber(
                message: "Card number can not be blank.",
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            errors.append(err)
        } else if !rawData.cardNumber.isValidCardNumber {
            let err = PrimerValidationError.invalidCardnumber(
                message: "Card number is not valid.",
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            errors.append(err)
        }

        do {
            try rawData.expiryDate.validateExpiryDateString()
        } catch {
            if let err = error as? PrimerValidationError {
                errors.append(err)
            }
        }

        if rawData.cvv.isEmpty {
            let err = PrimerValidationError.invalidCvv(
                message: "CVV cannot be blank.",
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            errors.append(err)
        } else if !rawData.cvv.isValidCVV(cardNetwork: cardNetwork) {
            let err = PrimerValidationError.invalidCvv(
                message: "CVV is not valid.",
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            errors.append(err)
        }

        if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
            if (rawData.cardholderName ?? "").isEmpty {
                errors.append(PrimerValidationError.invalidCardholderName(
                    message: "Cardholder name cannot be blank.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                ))
            } else if !(rawData.cardholderName ?? "").isValidNonDecimalString {
                errors.append(PrimerValidationError.invalidCardholderName(
                    message: "Cardholder name is not valid.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                ))
            }
        }

        guard errors.isEmpty else {
            let err = PrimerError.underlyingErrors(
                errors: errors,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
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
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
