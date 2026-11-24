//
//  CardNetworkBadgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class CardNetworkBadgeTests: XCTestCase {
    func test_image_unknownNetwork_isTheGreyCardAtLogoSize() throws {
        let image = try XCTUnwrap(CardNetworkBadge.image(for: .unknown))

        XCTAssertEqual(image.size, CGSize(width: 28, height: 20))
    }

    func test_image_knownNetwork_isItsLogo() {
        XCTAssertEqual(CardNetworkBadge.image(for: .visa), CardNetwork.visa.icon)
    }
}
