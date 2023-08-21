//
//  PrimerHeadlessValidationTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 21/08/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class PrimerInputElementTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func test_validate_cardholderName() throws {
        let sut = PrimerInputElementType.cardholderName
        
        XCTAssertTrue(sut.validate(value: "Joe Bloggs", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "JoeBloggs", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "Joe Bloggs Jr.", detectedValueType: nil))
       
        let allTheLetters = CharacterSet.letters.union(.whitespaces).characters().reduce("", { $0 + "\($1)"})
        XCTAssertTrue(sut.validate(value: allTheLetters, detectedValueType: nil))
        
        // Test strings with numerics. Logic states these should fail
        XCTAssertFalse(sut.validate(value: "123", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "Joe Bloggs the 3rd", detectedValueType: nil))
        
        // Test non-string entry
        XCTAssertFalse(sut.validate(value: 123, detectedValueType: nil))
    }

}
