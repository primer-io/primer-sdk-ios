//
//  PollingModuleTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class PollingModuleTests: XCTestCase {
    func test_successful_polling() throws {
        let expectation = XCTestExpectation(description: "Poll URL | Success")

        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        PollingModule.apiClient = mockApiClient
        let pollingModule = PollingModule(url: URL(string: "https://random.url")!)

        firstly {
            pollingModule.start()
        }
        .done { _ in
            XCTAssert(true)
            expectation.fulfill()
        }
        .catch { _ in
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
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (nil, NSError(domain: "dummy-network-error", code: 100)),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        PollingModule.apiClient = mockApiClient
        let pollingModule = PollingModule(url: URL(string: "https://random.url")!)

        firstly {
            pollingModule.start()
        }
        .done { _ in
            XCTAssert(true)
            expectation.fulfill()
        }
        .catch { _ in
            XCTAssert(false)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func test_polling_failure_due_to_client_token() throws {
        let expectation = XCTestExpectation(description: "Poll URL | Failure")

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        PollingModule.apiClient = mockApiClient
        AppState.current.clientToken = nil

        let pollingModule = PollingModule(url: URL(string: "https://random.url")!)

        firstly {
            pollingModule.start()
        }
        .done { _ in
            XCTAssert(false, "Polling succeeded, but it should fail with error .invalidClientToken")
            expectation.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError, case .invalidClientToken = primerErr {
            } else {
                XCTAssert(false, "Polling failed with error \(err.localizedDescription), but it should fail with error .invalidClientToken")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }
}
