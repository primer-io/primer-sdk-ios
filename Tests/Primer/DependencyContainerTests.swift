//
//  DependencyContainerTests.swift
//  
//
//  Created by Niall Quinn on 23/07/24.
//

import XCTest
@testable import PrimerSDK

class DependencyContainerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testConcurrentRegistrationAndResolution() {
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
    
    func testConcurrentRegistrationOfSameType() {
        let expectation = self.expectation(description: "Concurrent registrations completed")
        let operationsCount = 1000
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        let appState = MockAppState()
        
        for i in 0..<operationsCount {
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
    
    func testConcurrentResolutionOfNonExistentDependency() {
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
    
    func testConcurrentRegistrationAndResolutionOfMultipleTypes() {
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
}
