//
//  PrimerFontRegistrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

/// CheckoutComponents draws its first screens before it reaches `Primer.shared`, which registered Inter.
/// This proves the fix only when run on its own: any earlier test that touches `Primer.shared` registers Inter too.
@available(iOS 15.0, *)
final class PrimerFontRegistrationTests: XCTestCase {

    func test_inter_resolvesWithoutAnyoneRegisteringItFirst() {
        let font = PrimerFont.uiFont(family: "Inter", weight: 400, size: 16)

        XCTAssertTrue(font.familyName.contains("Inter"), "got \(font.familyName)")
    }
}
