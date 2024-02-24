//
//  AssetsManagerTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 14/11/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

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

}
