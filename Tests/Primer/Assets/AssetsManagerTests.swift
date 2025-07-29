//
//  AssetsManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

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
}
