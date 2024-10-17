//
//  SecretsManaagerTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 16/10/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import Debug_App

final class SecretsManagerTests: XCTestCase {

    func testLoadFileAndGetSecret() throws {
        let stripePublishableKey = SecretsManager.shared.value(forKey: .stripePublishableKey)
        XCTAssertEqual(stripePublishableKey, "pk_test_...")
    }

}
