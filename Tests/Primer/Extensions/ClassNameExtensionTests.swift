//
//  ClassNameExtensionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class ClassNameExtensionTests: XCTestCase {

    func testClassName() {
        XCTAssertEqual(className, "ClassNameExtensionTests")
        XCTAssertEqual(ClassNameExtensionTests.className, "ClassNameExtensionTests")
    }

}
