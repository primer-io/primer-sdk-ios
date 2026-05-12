//
//  ClassNameExtensionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerFoundation

final class ClassNameExtensionTests: XCTestCase {

    func testClassName() {
        XCTAssertEqual(self.className, "ClassNameExtensionTests")
        XCTAssertEqual(ClassNameExtensionTests.className, "ClassNameExtensionTests")
    }

}
