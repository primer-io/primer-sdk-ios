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
                    Task { try? await self.validateRawData(rawCardData) }

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
                Task { try? await self.validateRawData(rawData) }
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

    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization {
        guard PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) != nil else {
            throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
        }

        guard let rawData = data as? PrimerCardData,
              (rawData.expiryDate.split(separator: "/")).count == 2 else {
            throw handled(primerError: .invalidValue(key: "rawData"))
        }

        // Validate card network before tokenization (only if card number is valid)
        // Use user-selected network if available (for co-badged cards), otherwise auto-detect
        if !rawData.cardNumber.isEmpty && rawData.cardNumber.isValidCardNumber {
            let cardNetwork = rawData.cardNetwork ?? CardNetwork(cardNumber: rawData.cardNumber)
            if !self.allowedCardNetworks.contains(cardNetwork) {
                throw handled(primerError: .invalidValue(key: "cardNetwork",
                                                         value: cardNetwork.displayName))
            }
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

    func validateRawData(_ data: PrimerRawData) async throws {
        try await validateRawData(data, cardNetworksMetadata: nil)
    }

    func validateRawData(_ data: PrimerRawData, cardNetworksMetadata: PrimerCardNumberEntryMetadata?) async throws {
        var errors: [PrimerValidationError] = []

        guard let rawData = data as? PrimerCardData else {
            let err = handled(primerValidationError: .invalidRawData())
            errors.append(err)
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw err
        }

        // Locally validated card network
        // Use user-selected network if available (for co-badged cards), otherwise auto-detect
        var cardNetwork = rawData.cardNetwork ?? CardNetwork(cardNumber: rawData.cardNumber)

        // Remotely validated card network
        if let cardNetworksMetadata = cardNetworksMetadata {
            let didDetectNetwork = !cardNetworksMetadata.detectedCardNetworks.items.isEmpty &&
                cardNetworksMetadata.detectedCardNetworks.items.map { $0.network } != [.unknown]

            if didDetectNetwork, cardNetworksMetadata.detectedCardNetworks.preferred == nil,
               let network = cardNetworksMetadata.detectedCardNetworks.items.first?.network {
                cardNetwork = network
            }
        }

        // Always trigger network validation (even for partial/invalid cards)
        // CardValidationService handles:
        // - < 8 digits: local validation
        // - >= 8 digits: remote BIN lookup
        // - Empty: local validation with empty networks
        // This ensures picker appears as user types, not just when card is fully valid
        self.cardValidationService?.validateCardNetworks(withCardNumber: rawData.cardNumber)

        // Invalid card number error - check this FIRST before network type validation
        if rawData.cardNumber.isEmpty {
            errors.append(PrimerValidationError.invalidCardnumber(message: "Card number can not be blank."))
        } else if !rawData.cardNumber.isValidCardNumber {
            errors.append(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
        } else {
            // Only validate network TYPE (allowed/disallowed) when card number is valid
            // This prevents "unsupported-card-type" errors for empty/partial cards
            if let cardNetworksMetadata = cardNetworksMetadata {
                // Unsupported card type error
                if !self.allowedCardNetworks.contains(cardNetwork) {
                    let err = PrimerValidationError.invalidCardType(
                        message: "Unsupported card type detected: \(cardNetwork.displayName)"
                    )
                    errors.append(err)
                }
            } else {
                // When BIN data is not available, validate locally detected network against allowed networks
                // This ensures consistent behavior with Web SDK where network validation always happens
                if !self.allowedCardNetworks.contains(cardNetwork) {
                    let err = PrimerValidationError.invalidCardType(
                        message: "Unsupported card type detected: \(cardNetwork.displayName)"
                    )
                    errors.append(err)
                }
            }
        }

        do {
            try rawData.expiryDate.validateExpiryDateString()
        } catch {
            if let err = error as? PrimerValidationError {
                errors.append(err)
            }
        }

        if rawData.cvv.isEmpty {
            errors.append(PrimerValidationError.invalidCvv(message: "CVV cannot be blank."))
        } else if !rawData.cvv.isValidCVV(cardNetwork: cardNetwork) {
            errors.append(PrimerValidationError.invalidCvv(message: "CVV is not valid."))
        }

        if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
            if (rawData.cardholderName ?? "").isEmpty {
                errors.append(PrimerValidationError.invalidCardholderName(message: "Cardholder name cannot be blank."))
            } else if !(rawData.cardholderName ?? "").isValidNonDecimalString {
                errors.append(PrimerValidationError.invalidCardholderName(message: "Cardholder name is not valid."))
            }
        }

        guard errors.isEmpty else {
            let err = handled(primerError: .underlyingErrors(errors: errors))
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
