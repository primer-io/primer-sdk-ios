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

        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .cartesBancaires)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .discover)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .masterCard)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .visa)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .amex)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .elo)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .diners)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .jcb)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .maestro)?.cardImage)
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .mir)?.cardImage)

        XCTAssertNil(try AssetsManager.getCardNetworkAsset(for: .unknown)?.cardImage)
    }

}
