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
}
