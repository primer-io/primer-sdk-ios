//
//  DependencyContainerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class DependencyContainerTests: XCTestCase {

    func test_concurrentRegistrationAndResolution() {
        let expectation = self.expectation(description: "Concurrent operations completed")
        let operationsCount = 1000
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)

        let appState = MockAppState()

        for i in 0..<operationsCount {
            queue.async {
                if i % 2 == 0 {
                    DependencyContainer.register(appState)
                } else {
                    _ = DependencyContainer.resolve() as AppStateProtocol
                }
            }
        }

        queue.async(flags: .barrier) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)
    }

    func test_concurrentRegistrationOfSameType() {
        let expectation = self.expectation(description: "Concurrent registrations completed")
        let operationsCount = 1000
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)

        let appState = MockAppState()

        for _ in 0..<operationsCount {
            queue.async {
                DependencyContainer.register(appState)
            }
        }

        queue.async(flags: .barrier) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)

        let resolvedState: AppStateProtocol = DependencyContainer.resolve()

        XCTAssertNotNil(resolvedState)
    }

    func test_concurrentResolutionOfNonExistentDependency() {
        let expectation = self.expectation(description: "Concurrent resolutions completed")
        let operationsCount = 1000
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)

        for _ in 0..<operationsCount {
            queue.async {
                XCTAssertNil(DependencyContainer.resolve() as Int?)
            }
        }

        queue.async(flags: .barrier) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_concurrentRegistrationAndResolutionOfMultipleTypes() {
        let expectation = self.expectation(description: "Concurrent operations completed")
        let operationsCount = 1000
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)

        let appState = MockAppState()
        let settings = MockPrimerSettings()

        for i in 0..<operationsCount {
            queue.async {
                switch i % 2 {
                case 0:
                    DependencyContainer.register(appState)
                case 1:
                    DependencyContainer.register(settings)
                default:
                    break
                }
            }
        }

        for _ in 0..<operationsCount {
            queue.async {
                _ = DependencyContainer.resolve() as AppStateProtocol
                _ = DependencyContainer.resolve() as PrimerSettingsProtocol
            }
        }

        queue.async(flags: .barrier) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)

        // Verify that the last value of each type was registered
        XCTAssertNotNil(DependencyContainer.resolve() as AppStateProtocol)
        XCTAssertNotNil(DependencyContainer.resolve() as PrimerSettingsProtocol)
    }

    func test_concurrentQueues() {
        let expectation = XCTestExpectation(description: "Concurrent access")
        let iterationCount = 1000
        let concurrentQueues = 4

        for _ in 0..<concurrentQueues {
            DispatchQueue.global().async {
                for _ in 0..<iterationCount {
                    // Register a unique dependency
                    let dependency = MockPrimerSettings()
                    DependencyContainer.register(dependency)

                    // Immediately resolve the dependency
                    let resolved: MockPrimerSettings = DependencyContainer.resolve()

                    // Verify that the resolved dependency matches the registered one
                    XCTAssertEqual(dependency.paymentHandling, resolved.paymentHandling)
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }
}
