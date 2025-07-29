//
//  ClassNameExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class ClassNameExtensionTests: XCTestCase {

    func testClassName() {
        XCTAssertEqual(self.className, "ClassNameExtensionTests")
        XCTAssertEqual(ClassNameExtensionTests.className, "ClassNameExtensionTests")
    }

}
