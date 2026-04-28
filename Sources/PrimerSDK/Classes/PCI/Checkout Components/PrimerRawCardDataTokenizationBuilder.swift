//
//  PrimerRawCardDataTokenizationBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable file_length

import Foundation

final class PrimerRawCardDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawCardData = self.rawData as? PrimerCardData {
                // DBG: REMOVE BEFORE MERGE
                print(
                    "[DBG-RAW] rawData set — cardNumber='\(rawCardData.cardNumber)' " +
                        "cardNetwork=\(String(describing: rawCardData.cardNetwork)) " +
                        "expiry='\(rawCardData.expiryDate)' cvv='\(rawCardData.cvv)' " +
                        "name='\(rawCardData.cardholderName ?? "nil")'"
                )

                rawCardData.onDataDidChange = { [weak self] in
                    guard let self else { return }
                    // DBG: REMOVE BEFORE MERGE
                    print(
                        "[DBG-RAW] onDataDidChange — cardNumber='\(rawCardData.cardNumber)' " +
                            "cardNetwork=\(String(describing: rawCardData.cardNetwork))"
                    )
                    Task { try? await self.validateRawData(rawCardData) }

                    let newCardNetwork = CardNetwork(cardNumber: rawCardData.cardNumber)
                    if newCardNetwork != self.cardNetwork {
                        self.cardNetwork = newCardNetwork
                    }
                }

                // Trigger initial validation for newly set data
                // This is necessary because didSet observers don't fire during initialization
                // so onDataDidChange won't be called for the initial data
                rawCardData.onDataDidChange?()

                let newCardNetwork = CardNetwork(cardNumber: rawCardData.cardNumber)
                if newCardNetwork != self.cardNetwork {
                    self.cardNetwork = newCardNetwork
                }
            } else {
                if self.cardNetwork != .unknown {
                    self.cardNetwork = .unknown
                }
            }
        }
    }

    weak var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?

    var cardValidationService: CardValidationService?

    var isDataValid: Bool = false
    var paymentMethodType: String

    public private(set) var cardNetwork: CardNetwork = .unknown {
        didSet {
            guard let rawDataManager else { return }

            DispatchQueue.main.async {
                rawDataManager.delegate?.primerRawDataManager?(
                    rawDataManager,
                    metadataDidChange: ["cardNetwork": self.cardNetwork.rawValue]
                )
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

    static func preferredNetwork(from cardNetwork: CardNetwork?) -> String? {
        // DBG: REMOVE BEFORE MERGE
        let resolved: String? = {
            guard PrimerInternal.shared.sdkIntegrationType == .headless else {
                return cardNetwork?.rawValue
            }
            return cardNetwork?.allowsUserSelection == true ? cardNetwork?.rawValue : nil
        }()
        print(
            "[DBG-SUBMIT] preferredNetwork(from:) cardNetwork=\(String(describing: cardNetwork)) " +
                "integrationType=\(String(describing: PrimerInternal.shared.sdkIntegrationType)) " +
                "allowsUserSelection=\(cardNetwork?.allowsUserSelection.description ?? "n/a") " +
                "→ resolved=\(String(describing: resolved))"
        )
        return resolved
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

        // DBG: REMOVE BEFORE MERGE
        print(
            "[DBG-SUBMIT] makeRequestBodyWithRawData — cardNumber='\(rawData.cardNumber)' " +
                "rawData.cardNetwork=\(String(describing: rawData.cardNetwork)) " +
                "expiry='\(rawData.expiryDate)' cvv.length=\(rawData.cvv.count) " +
                "name='\(rawData.cardholderName ?? "nil")'"
        )

        // The "card type allowed?" check belongs to validation, not the request builder.
        // `RawDataManager.submit` always runs `validateRawData` before this — and Android's
        // `CardTokenizationDelegate` doesn't repeat the check either.

        let expiryMonth = String((rawData.expiryDate.split(separator: "/"))[0])
        let rawExpiryYear = String((rawData.expiryDate.split(separator: "/"))[1])

        guard let expiryYear = rawExpiryYear.normalizedFourDigitYear() else {
            throw handled(primerValidationError: .invalidExpiryDate(
                message: "Expiry year '\(rawExpiryYear)' is not valid. Please provide a 2-digit (YY) or 4-digit (YYYY) year."
            ))
        }

        // DBG: REMOVE BEFORE MERGE — the value the SDK is about to send to the server
        let resolvedPreferredNetwork = Self.preferredNetwork(from: rawData.cardNetwork)
        print(
            "[DBG-SUBMIT] CardPaymentInstrument.preferredNetwork=\(String(describing: resolvedPreferredNetwork)) " +
                "(from rawData.cardNetwork=\(String(describing: rawData.cardNetwork)))"
        )

        return Request.Body.Tokenization(
            paymentInstrument: CardPaymentInstrument(
                number: (PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as? String) ?? rawData.cardNumber,
                cvv: rawData.cvv,
                expirationMonth: expiryMonth,
                expirationYear: expiryYear,
                cardholderName: rawData.cardholderName,
                preferredNetwork: resolvedPreferredNetwork
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) async throws {
        // Consult the BIN cache so per-keystroke validation uses the server's authoritative
        // answer once available, instead of re-deriving the network from local IIN ranges.
        let cached = (data as? PrimerCardData).flatMap {
            cardValidationService?.cachedMetadata(forCardNumber: $0.cardNumber)
        }
        // DBG: REMOVE BEFORE MERGE
        print(
            "[DBG-VAL] validateRawData(_:) cacheLookup=\(cached == nil ? "MISS" : "HIT") " +
                "detected=\(cached?.detectedCardNetworks.items.map(\.network.rawValue) ?? []) " +
                "selectable=\(cached?.selectableCardNetworks?.items.map(\.network.rawValue) ?? [])"
        )
        try await validateRawData(data, cardNetworksMetadata: cached)
    }

    func validateRawData(_ data: PrimerRawData, cardNetworksMetadata: PrimerCardNumberEntryMetadata?) async throws {
        var errors: [PrimerValidationError] = []

        guard let rawData = data as? PrimerCardData else {
            let err = handled(primerValidationError: .invalidRawData())
            errors.append(err)
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw err
        }

        // Resolve a card network for CVV-length use. Precedence:
        //   1. user-selected (`rawData.cardNetwork`) — explicit pick on a co-badged card
        //   2. BIN metadata's `preferred` / first detected — server's authoritative answer
        //   3. local card-number detection — best-effort fallback before BIN data arrives
        var cardNetwork: CardNetwork = rawData.cardNetwork ?? CardNetwork(cardNumber: rawData.cardNumber)
        // DBG: REMOVE BEFORE MERGE
        let cardNetworkInitial = cardNetwork

        if rawData.cardNetwork == nil, let metadata = cardNetworksMetadata {
            let detected = metadata.detectedCardNetworks
            let didDetectNetwork = !detected.items.isEmpty && detected.items.map(\.network) != [.unknown]
            if didDetectNetwork {
                cardNetwork = detected.preferred?.network
                    ?? detected.items.first?.network
                    ?? cardNetwork
            }
        }
        // DBG: REMOVE BEFORE MERGE
        print(
            "[DBG-VAL] resolveNetwork rawData.cardNetwork=\(String(describing: rawData.cardNetwork)) " +
                "initial=\(cardNetworkInitial.rawValue) " +
                "final=\(cardNetwork.rawValue) " +
                "metadataNil=\(cardNetworksMetadata == nil) " +
                "allowed=\(allowedCardNetworks.map(\.rawValue))"
        )

        // Always trigger network validation (even for partial/invalid cards)
        // CardValidationService handles:
        // - < 8 digits: local validation
        // - >= 8 digits: remote BIN lookup
        // - Empty: local validation with empty networks
        // This ensures picker appears as user types, not just when card is fully valid
        self.cardValidationService?.validateCardNetworks(withCardNumber: rawData.cardNumber)

        // Card-number / network errors. Mirrors Android `CardNumberValidator`:
        //   - Only run the unsupported-card-type check when the cache has BIN-derived
        //     metadata (REMOTE / LOCAL_FALLBACK). Local IIN guesses (e.g. Maestro for
        //     5017…) aren't authoritative enough to reject — wait for the BIN response.
        //   - When metadata is authoritative, "any detected network is allowed" is the
        //     check, not "the resolved network is in the allowed list" — keeps cobadged
        //     cards valid even when the user hasn't picked yet.
        if rawData.cardNumber.isEmpty {
            errors.append(PrimerValidationError.invalidCardnumber(message: "Card number can not be blank."))
        } else if let metadata = cardNetworksMetadata, metadata.source != .local {
            let detected = metadata.detectedCardNetworks.items
            if !detected.isEmpty, !detected.contains(where: \.allowed) {
                errors.append(PrimerValidationError.invalidCardType(
                    message: "Unsupported card type detected: \(detected.first?.displayName ?? cardNetwork.displayName)"
                ))
            } else if !rawData.cardNumber.isValidCardNumber {
                errors.append(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
            }
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
            // DBG: REMOVE BEFORE MERGE
            print("[DBG-VAL] FAILED errors=\(errors.map { "\(type(of: $0)): \($0.localizedDescription)" })")
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw PrimerError.underlyingErrors(errors: errors)
        }

        // DBG: REMOVE BEFORE MERGE
        print("[DBG-VAL] PASSED")
        notifyDelegateOfValidationResult(isValid: true, errors: nil)
    }

    private func notifyDelegateOfValidationResult(isValid: Bool, errors: [Error]?) {
        // DBG: REMOVE BEFORE MERGE
        print("[DBG-VAL] notifyDelegate isValid=\(isValid) errorCount=\(errors?.count ?? 0)")
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
