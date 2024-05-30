//
//  ClassNameExtensionTests.swift
//  
//
//  Created by Jack Newcombe on 10/05/2024.
//

import XCTest
@testable import PrimerSDK

final class ClassNameExtensionTests: XCTestCase {

    func testClassName() {
        XCTAssertEqual(self.className, "ClassNameExtensionTests")
        XCTAssertEqual(ClassNameExtensionTests.className, "ClassNameExtensionTests")
    }

}
