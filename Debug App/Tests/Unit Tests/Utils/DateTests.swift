//
//  DateTests.swift
//  Debug App Tests
//
//  Created by Evangelos on 12/1/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class PrimerDateTests: XCTestCase {

    func test_expiry_date_validation() throws {
        var invalidExpiryDate = ""

        do {
            try invalidExpiryDate.validateExpiryDateString()
            XCTAssert(false, "\(invalidExpiryDate) should not be a valid date.")

        } catch {
            if let err = error as? PrimerValidationError {
                XCTAssert(err.localizedDescription == "[invalid-expiry-date] Expiry date cannot be blank.", "Error should be '[invalid-expiry-date] Expiry date cannot be blank.'")
            } else {
                XCTAssert(false, "Error should be of type 'PrimerValidationError'.")
            }
        }

        invalidExpiryDate = "a"

        do {
            try invalidExpiryDate.validateExpiryDateString()
            XCTAssert(false, "\(invalidExpiryDate) should not be a valid date.")

        } catch {
            if let err = error as? PrimerValidationError {
                XCTAssert(err.localizedDescription == "[invalid-expiry-date] Card expiry date is not valid. Valid expiry date format is MM/YYYY.", "Error should be '[invalid-expiry-date] Card expiry date is not valid. Valid expiry date format is MM/YYYY.'")
            } else {
                XCTAssert(false, "Error should be of type 'PrimerValidationError'.")
            }
        }

        invalidExpiryDate = "ab/2040"

        do {
            try invalidExpiryDate.validateExpiryDateString()
            XCTAssert(false, "\(invalidExpiryDate) should not be a valid date.")

        } catch {
            if let err = error as? PrimerValidationError {
                XCTAssert(err.localizedDescription == "[invalid-expiry-date] Card expiry date is not valid. Valid expiry date format is MM/YYYY.", "Error should be '[invalid-expiry-date] Card expiry date is not valid. Valid expiry date format is MM/YYYY.'")
            } else {
                XCTAssert(false, "Error should be of type 'PrimerValidationError'.")
            }
        }

        invalidExpiryDate = "02/2020"

        do {
            try invalidExpiryDate.validateExpiryDateString()
            XCTAssert(false, "\(invalidExpiryDate) should not be a valid date.")

        } catch {
            if let err = error as? PrimerValidationError {
                XCTAssert(err.localizedDescription == "[invalid-expiry-date] Card expiry date is not valid. Expiry date should not be less than a year in the past.", "Error should be '[invalid-expiry-date] Card expiry date is not valid. Expiry date should not be less than a year in the past.'")
            } else {
                XCTAssert(false, "Error should be of type 'PrimerValidationError'.")
            }
        }

        let now = Date()
        let nowDateComponents = Calendar.current.dateComponents([.month, .year], from: now)

        let currentMonth = nowDateComponents.month!
        let currentYear = nowDateComponents.year!

        let oneYearAgo = currentYear - 1
        let oneYearAgoStr = "\(String(currentMonth).paddingToLeft(upTo: 2, using: "0"))/\(String(oneYearAgo))"
        print("oneYearAgoStr: \(oneYearAgoStr)")

        let oneYearAndOneMonthAgoStr: String

        if currentMonth > 1 {
            oneYearAndOneMonthAgoStr = "\(String(currentMonth - 1).paddingToLeft(upTo: 2, using: "0"))/\(String(oneYearAgo))"
        } else {
            oneYearAndOneMonthAgoStr = "\(String(12).paddingToLeft(upTo: 2, using: "0"))/\(String(oneYearAgo - 1))"
        }

        print("oneYearAndOneMonthAgoStr: \(oneYearAndOneMonthAgoStr)")

        invalidExpiryDate = oneYearAndOneMonthAgoStr
        print(invalidExpiryDate)

        do {
            try invalidExpiryDate.validateExpiryDateString()
            XCTAssert(false, "\(invalidExpiryDate) should not be a valid date.")
        } catch {
            if let err = error as? PrimerValidationError {
                XCTAssert(err.localizedDescription == "[invalid-expiry-date] Card expiry date is not valid. Expiry date should not be less than a year in the past.", "Error should be '[invalid-expiry-date] Card expiry date is not valid. Expiry date should not be less than a year in the past.'")
            } else {
                XCTAssert(false, "Error should be of type 'PrimerValidationError'.")
            }
        }

        let validExpiryDate = oneYearAgoStr
        do {
            try validExpiryDate.validateExpiryDateString()
            XCTAssert(true, "\(validExpiryDate) should be a valid date.")
        } catch {
            if let err = error as? PrimerValidationError {
                XCTAssert(err.localizedDescription == "[invalid-expiry-date] Card expiry date is not valid. Expiry date should not be less than a year in the past.", "Error should be '[invalid-expiry-date] Card expiry date is not valid. Expiry date should not be less than a year in the past.'")
            } else {
                XCTAssert(false, "Error should be of type 'PrimerValidationError'.")
            }
        }
    }
}

private extension RangeReplaceableCollection where Self: StringProtocol {
    func paddingToLeft(upTo length: Int, using element: Element = " ") -> SubSequence {
        return repeatElement(element, count: Swift.max(0, length-count)) + suffix(Swift.max(count, count-length))
    }
}
