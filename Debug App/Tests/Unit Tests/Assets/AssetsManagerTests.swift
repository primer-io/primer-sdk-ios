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
        XCTAssertNotNil(try AssetsManager.getCardNetworkAssets(for: .cartesBancaires))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAssets(for: .discover))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAssets(for: .masterCard))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAssets(for: .visa))
        XCTAssertNotNil(try AssetsManager.getCardNetworkAssets(for: .amex))

        XCTAssertNil(try AssetsManager.getCardNetworkAssets(for: .elo))
    }

}
