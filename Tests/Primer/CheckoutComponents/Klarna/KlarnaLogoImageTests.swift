//
//  KlarnaLogoImageTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class KlarnaLogoImageTests: XCTestCase {

    func test_klarnaLogos_loadForLightAndDarkSheets() {
        XCTAssertNotNil(UIImage.klarnaLogoLight)
        XCTAssertNotNil(UIImage.klarnaLogoDark)
    }
}
