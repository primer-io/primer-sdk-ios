//
//  PollingModuleAsyncTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class PollingModuleAsyncTests: XCTestCase {
    func test_successful_polling_async() async throws {
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        PollingModule.apiClient = mockApiClient
        let pollingModule = PollingModule(url: URL(string: "https://random.url")!)

        do {
            _ = try await pollingModule.start()
            XCTAssert(true)
        } catch {
            XCTAssert(false, "Polling failed with error: \(error.localizedDescription)")
        }
    }

    func test_successful_polling_with_network_error_async() async throws {
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (nil, NSError(domain: "dummy-network-error", code: 100)),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        PollingModule.apiClient = mockApiClient
        let pollingModule = PollingModule(url: URL(string: "https://random.url")!)

        do {
            _ = try await pollingModule.start()
            XCTAssert(true)
        } catch {
            XCTAssert(false, "Polling failed with error: \(error.localizedDescription)")
        }
    }

    func test_polling_failure_due_to_client_token_async() async throws {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        PollingModule.apiClient = mockApiClient
        AppState.current.clientToken = nil

        let pollingModule = PollingModule(url: URL(string: "https://random.url")!)

        do {
            _ = try await pollingModule.start()
            XCTFail("Polling succeeded, but it should fail with error .invalidClientToken")
        } catch {
            guard let primerErr = error as? PrimerError, case .invalidClientToken = primerErr else {
                return XCTFail("Polling failed with error \(error.localizedDescription), but it should fail with error .invalidClientToken")
            }
        }
    }
}
