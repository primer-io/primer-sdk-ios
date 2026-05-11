//
//  PrimerRawCardDataTokenizationBuilderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PrimerRawCardDataTokenizationBuilderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        PrimerInternal.shared.sdkIntegrationType = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - preferredNetwork

    func test_preferredNetwork_headless_returnsNilForEftpos() {
        PrimerInternal.shared.sdkIntegrationType = .headless
        let result = PrimerRawCardDataTokenizationBuilder.preferredNetwork(from: .eftpos)
        XCTAssertNil(result, "EFTPOS should not be sent as preferredNetwork in headless mode")
    }

    func test_preferredNetwork_headless_returnsValueForSelectableNetwork() {
        PrimerInternal.shared.sdkIntegrationType = .headless
        let result = PrimerRawCardDataTokenizationBuilder.preferredNetwork(from: .cartesBancaires)
        XCTAssertEqual(result, CardNetwork.cartesBancaires.rawValue)
    }

    func test_preferredNetwork_dropIn_returnsValueForEftpos() {
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let result = PrimerRawCardDataTokenizationBuilder.preferredNetwork(from: .eftpos)
        XCTAssertEqual(result, CardNetwork.eftpos.rawValue)
    }

    // MARK: - makeRequestBodyWithRawData

    func test_makeRequestBody_headless_sendsNilPreferredNetworkForEftpos() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.visa, .eftpos])
        PrimerInternal.shared.sdkIntegrationType = .headless
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let cardData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "Test",
            cardNetwork: .eftpos
        )

        let body = try await sut.makeRequestBodyWithRawData(cardData)
        let instrument = body.paymentInstrument as? CardPaymentInstrument
        XCTAssertNil(instrument?.preferredNetwork, "EFTPOS should not be sent as preferredNetwork in headless mode")
    }

    func test_makeRequestBody_headless_sendsPreferredNetworkForSelectableNetwork() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.visa, .cartesBancaires])
        PrimerInternal.shared.sdkIntegrationType = .headless
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let cardData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "Test",
            cardNetwork: .cartesBancaires
        )

        let body = try await sut.makeRequestBodyWithRawData(cardData)
        let instrument = body.paymentInstrument as? CardPaymentInstrument
        XCTAssertEqual(instrument?.preferredNetwork, CardNetwork.cartesBancaires.rawValue)
    }

    // MARK: - validateRawData with metadata (covers cobadged / mis-classified-IIN cases)

    /// Card 5017… is locally classified as Maestro but the BIN response says CB+MC.
    /// With BIN metadata present and `cardNetwork == nil`, validation must use the
    /// metadata's allowed network (CB) — not fall back to the wrong local guess.
    func test_validate_cobadgedCard_withMetadata_andNilUserSelection_passes() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires, .visa, .masterCard])
        PrimerInternal.shared.sdkIntegrationType = .headless
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let cardData = PrimerCardData(
            cardNumber: "5017679210000700",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Smith"
        )
        let metadata = PrimerCardNumberEntryMetadata(
            source: .remote,
            selectableCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ],
            detectedCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ]
        )

        try await sut.validateRawData(cardData, cardNetworksMetadata: metadata)
        XCTAssertTrue(sut.isDataValid)
    }

    /// Same card, but the user has explicitly picked CB. User pick wins; validation passes.
    func test_validate_cobadgedCard_withUserSelection_passes() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires, .visa, .masterCard])
        PrimerInternal.shared.sdkIntegrationType = .headless
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let cardData = PrimerCardData(
            cardNumber: "5017679210000700",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Smith",
            cardNetwork: .cartesBancaires
        )
        let metadata = PrimerCardNumberEntryMetadata(
            source: .remote,
            selectableCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ],
            detectedCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ]
        )

        try await sut.validateRawData(cardData, cardNetworksMetadata: metadata)
        XCTAssertTrue(sut.isDataValid)
    }

    /// Mirrors Android `CardNumberValidator`: without BIN-derived metadata, the validator
    /// must NOT reject based on the local IIN guess. For `5017…` the local guess is Maestro
    /// (not in the merchant's allowed list), but the BIN response will reveal CB+MC. Until
    /// it arrives, validation passes if the card number is structurally valid.
    func test_validate_misclassifiedLocalIIN_withoutMetadata_passes_byLuhnAlone() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires, .visa, .masterCard])
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let cardData = PrimerCardData(
            cardNumber: "5017679210000700",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Smith"
        )

        try await sut.validateRawData(cardData, cardNetworksMetadata: nil)
        XCTAssertTrue(sut.isDataValid)
    }

    /// `source = .local` means the cache only has a partial-typing local-IIN guess. The
    /// validator must not run the allowed-list check against that — same as Android skipping
    /// the check when `source == LOCAL`.
    func test_validate_misclassifiedLocalIIN_withLocalSourceMetadata_passes() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires, .visa, .masterCard])
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let cardData = PrimerCardData(
            cardNumber: "5017679210000700",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Smith"
        )
        let localMetadata = PrimerCardNumberEntryMetadata(
            source: .local,
            selectableCardNetworks: nil,
            detectedCardNetworks: [PrimerCardNetwork(network: .maestro)]
        )

        try await sut.validateRawData(cardData, cardNetworksMetadata: localMetadata)
        XCTAssertTrue(sut.isDataValid)
    }

    /// Once the BIN service has actually been consulted (`source = .localFallback` after a
    /// failed remote lookup, or `.remote` on success) and every detected network is outside
    /// the merchant's allowed list, validation must reject — matching Android.
    func test_validate_disallowedCard_withRemoteMetadata_failsWithUnsupportedCardType() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires, .visa, .masterCard])
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let cardData = PrimerCardData(
            cardNumber: "6011000990139424",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Smith"
        )
        let remoteMetadata = PrimerCardNumberEntryMetadata(
            source: .remote,
            selectableCardNetworks: nil,
            detectedCardNetworks: [PrimerCardNetwork(network: .discover)]
        )

        do {
            try await sut.validateRawData(cardData, cardNetworksMetadata: remoteMetadata)
            XCTFail("Expected validation to fail because Discover is not in the allowed list")
        } catch {
            XCTAssertFalse(sut.isDataValid)
        }
    }

    /// `makeRequestBodyWithRawData` itself no longer runs an allowed-list check (that's
    /// validation's job). With user pick = nil and a remote-cache hit indicating CB+MC are
    /// both allowed, the request must succeed and `preferredNetwork` must stay nil so the
    /// server picks.
    func test_makeRequestBody_cobadgedCard_withNilCardNetwork_andCachedAllowedNetwork_succeeds() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires, .visa, .masterCard])
        PrimerInternal.shared.sdkIntegrationType = .headless
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let stub = StubCardValidationService()
        stub.stubbedMetadata = PrimerCardNumberEntryMetadata(
            source: .remote,
            selectableCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ],
            detectedCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ]
        )
        sut.cardValidationService = stub

        let cardData = PrimerCardData(
            cardNumber: "5017679210000700",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let body = try await sut.makeRequestBodyWithRawData(cardData)
        let instrument = body.paymentInstrument as? CardPaymentInstrument
        // User didn't tap, so we must NOT send a preferredNetwork. Server picks.
        XCTAssertNil(instrument?.preferredNetwork)
    }

    func test_validate_consultsBinCache_whenNoMetadataIsPassed() async throws {
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires, .visa, .masterCard])
        let sut = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        let stub = StubCardValidationService()
        stub.stubbedMetadata = PrimerCardNumberEntryMetadata(
            source: .remote,
            selectableCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ],
            detectedCardNetworks: [
                PrimerCardNetwork(network: .cartesBancaires),
                PrimerCardNetwork(network: .masterCard)
            ]
        )
        sut.cardValidationService = stub

        let cardData = PrimerCardData(
            cardNumber: "5017679210000700",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Smith"
        )

        try await sut.validateRawData(cardData)
        XCTAssertTrue(sut.isDataValid)
        XCTAssertEqual(stub.lookupRequests, ["5017679210000700"])
    }
}

// MARK: - Test stubs

private final class StubCardValidationService: CardValidationService {
    var stubbedMetadata: PrimerCardNumberEntryMetadata?
    private(set) var lookupRequests: [String] = []

    func validateCardNetworks(withCardNumber cardNumber: String) {}

    func createValidationMetadata(
        networks: [CardNetwork],
        source: PrimerCardValidationSource
    ) -> PrimerCardNumberEntryMetadata {
        PrimerCardNumberEntryMetadata(
            source: source,
            selectableCardNetworks: nil,
            detectedCardNetworks: networks.map(PrimerCardNetwork.init(network:))
        )
    }

    func cachedMetadata(forCardNumber cardNumber: String) -> PrimerCardNumberEntryMetadata? {
        lookupRequests.append(cardNumber)
        return stubbedMetadata
    }
}
