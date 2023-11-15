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
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .cartesBancaires))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .discover))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .masterCard))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .visa))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAsset(for: .amex))

        XCTAssertNil(try AssetsManager.getCardNetworkAsset(for: .elo))
    }

}
