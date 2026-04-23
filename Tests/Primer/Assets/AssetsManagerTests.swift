//
//  AssetsManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class AssetsManagerTests: XCTestCase {

    typealias AssetsManager = PrimerHeadlessUniversalCheckout.AssetsManager

    override func setUpWithError() throws {
        SDKSessionHelper.setUp()
    }

    override func tearDownWithError() throws {
        SDKSessionHelper.tearDown()
    }

    func testCardAssets() throws {

        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .cartesBancaires)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .discover)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .masterCard)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .visa)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .amex)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .elo)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .diners)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .jcb)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .maestro)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .mir)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .unknown)?.cardImage)

    }

    func testGetNetworkAssetForString() throws {
        XCTAssertEqual(AssetsManager.getCardNetworkAsset(cardNetworkString: "VISA")?.cardNetwork, .visa)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(cardNetworkString: "VISA")?.cardImage)

        XCTAssertEqual(AssetsManager.getCardNetworkAsset(cardNetworkString: "MASTERCARD")?.cardNetwork, .masterCard)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(cardNetworkString: "MASTERCARD")?.cardImage)

        XCTAssertEqual(AssetsManager.getCardNetworkAsset(cardNetworkString: "CARTES_BANCAIRES")?.cardNetwork, .cartesBancaires)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(cardNetworkString: "CARTES_BANCAIRES")?.cardImage)
    }

    // MARK: - Card Network Traits

    func testGetCardNetworkTraitsForNetworkWithValidation() throws {
        let traits = try XCTUnwrap(AssetsManager.getCardNetworkTraits(for: .amex))
        XCTAssertEqual(traits.cardNetwork, .amex)
        XCTAssertEqual(traits.cvvLabel, "CID")
        XCTAssertEqual(traits.cvvLength, 4)
    }

    func testGetCardNetworkTraitsForNetworkWithoutValidation() {
        XCTAssertNil(AssetsManager.getCardNetworkTraits(for: .bancontact))
        XCTAssertNil(AssetsManager.getCardNetworkTraits(for: .unknown))
    }

    func testGetCardNetworkTraitsForString() {
        XCTAssertEqual(AssetsManager.getCardNetworkTraits(cardNetworkString: "VISA")?.cardNetwork, .visa)
        XCTAssertEqual(AssetsManager.getCardNetworkTraits(cardNetworkString: "AMEX")?.cardNetwork, .amex)
        XCTAssertEqual(AssetsManager.getCardNetworkTraits(cardNetworkString: "MASTERCARD")?.cardNetwork, .masterCard)
    }

    func testGetCardNetworkTraitsForNilOrUnknownString() {
        XCTAssertNil(AssetsManager.getCardNetworkTraits(cardNetworkString: nil))
        XCTAssertNil(AssetsManager.getCardNetworkTraits(cardNetworkString: "FOO"))
    }
}
