//
//  LongPollingModuleTests.swift
//  Primer.io Example App
//
//  Created by Evangelos on 22/9/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PollingModuleTests: XCTestCase {
    
    func test_successful_polling() throws {
        let expectation = XCTestExpectation(description: "Poll URL | Success")
        
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil),
            (PollingResponse(status: .pending, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil),
            (PollingResponse(status: .complete, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil)
        ]
        
        let pollingModule = PollingModule(url: URL(string: "https://random.url")!, apiClient: mockApiClient)
        
        firstly {
            pollingModule.start()
        }
        .done { resumeToken in
            XCTAssert(true)
            expectation.fulfill()
        }
        .catch { err in
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func test_successful_polling_with_network_error() throws {
        let expectation = XCTestExpectation(description: "Poll URL | Success")
        
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil),
            (nil, NSError(domain: "dummy-network-error", code: 100)),
            (PollingResponse(status: .complete, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil)
        ]
        
        let pollingModule = PollingModule(url: URL(string: "https://random.url")!, apiClient: mockApiClient)
        
        firstly {
            pollingModule.start()
        }
        .done { resumeToken in
            XCTAssert(true)
            expectation.fulfill()
        }
        .catch { err in
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func test_polling_failure_due_to_client_token() throws {
        let expectation = XCTestExpectation(description: "Poll URL | Failure")
                
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil),
            (PollingResponse(status: .pending, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil),
            (PollingResponse(status: .complete, id: "0", source: "src", urls: PollingURLs(status: "", redirect: "", complete: "")), nil)
        ]
        
        let pollingModule = PollingModule(url: URL(string: "https://random.url")!, apiClient: mockApiClient)
        
        firstly {
            pollingModule.start()
        }
        .done { resumeToken in
            XCTAssert(false, "Polling succeeded, but it should fail with error .invalidClientToken")
            expectation.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError, case .invalidClientToken = primerErr {
                XCTAssert(true)
            } else {
                XCTAssert(false, "Polling failed with error \(err.localizedDescription), but it should fail with error .invalidClientToken")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
}


#endif
