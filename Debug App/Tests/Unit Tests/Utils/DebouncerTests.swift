//
//  DebouncerTests.swift
//  Debug App Tests
//
//  Created by Boris on 31.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class DebouncerTests: XCTestCase {

    func testDebounce() {
        let expectation = self.expectation(description: "Debouncer should debounce multiple calls and only execute the last one")
        let debouncer = Debouncer(delay: 0.2)
        var executedActions = [String]()

        debouncer.debounce {
            executedActions.append("First")
        }
        debouncer.debounce {
            executedActions.append("Second")
        }
        debouncer.debounce {
            executedActions.append("Third")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.3) { _ in
            XCTAssertEqual(executedActions, ["Third"], "Debouncer did not debounce correctly")
        }
    }

    func testCancel() {
        let expectation = self.expectation(description: "Debouncer should cancel the action")
        let debouncer = Debouncer(delay: 0.2)
        var executedActions = [String]()

        debouncer.debounce {
            executedActions.append("First")
        }
        debouncer.debounce {
            executedActions.append("Second")
        }
        debouncer.cancel()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertTrue(executedActions.isEmpty, "Debouncer did not cancel correctly")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.4)
    }

    func testExecuteAfterDelay() {
        let expectation = self.expectation(description: "Debouncer should execute the action after the specified delay")
        let debouncer = Debouncer(delay: 0.2)
        var executedActions = [String]()

        debouncer.debounce {
            executedActions.append("First")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.3) { _ in
            XCTAssertEqual(executedActions, ["First"], "Debouncer did not execute the action after the specified delay")
        }
    }
}
