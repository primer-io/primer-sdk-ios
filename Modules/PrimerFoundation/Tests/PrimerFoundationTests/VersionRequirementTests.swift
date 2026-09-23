//
//  VersionRequirementTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class VersionRequirementTests: XCTestCase {
    func testCaretAllowsUpToTheNextMajor() {
        let requirement = VersionRequirement("^1.0.0")
        for satisfying in ["1.0.0", "1.0.5", "1.7.2"] {
            XCTAssertTrue(requirement.isSatisfied(by: version(satisfying)), satisfying)
        }
        for failing in ["0.9.9", "2.0.0"] {
            XCTAssertFalse(requirement.isSatisfied(by: version(failing)), failing)
        }
    }

    func testCaretEnforcesTheMinimum() {
        let requirement = VersionRequirement("^1.2.0")
        XCTAssertTrue(requirement.isSatisfied(by: version("1.9.0")))
        XCTAssertFalse(requirement.isSatisfied(by: version("1.1.0")))
    }

    func testBelowOneTheMinorIsBreaking() {
        let requirement = VersionRequirement("^0.2.3")
        XCTAssertTrue(requirement.isSatisfied(by: version("0.2.9")))
        XCTAssertFalse(requirement.isSatisfied(by: version("0.2.2")))
        XCTAssertFalse(requirement.isSatisfied(by: version("0.3.0")))

        let patchOnly = VersionRequirement("^0.0.3")
        XCTAssertTrue(patchOnly.isSatisfied(by: version("0.0.3")))
        XCTAssertFalse(patchOnly.isSatisfied(by: version("0.0.4")))
    }

    func testUnrecognisedSyntaxIsNeverSatisfied() {
        for input in [">=1.0.0", "~1.0.0", "^1.2", "1.0.0", "^1.0.0 || ^2.0.0", ""] {
            let requirement = VersionRequirement(input)
            XCTAssertEqual(requirement, .unrecognised(input))
            XCTAssertFalse(requirement.isSatisfied(by: version("1.0.0")), input)
        }
    }

    private func version(_ string: String) -> SemanticVersion {
        SemanticVersion(string)!
    }
}
