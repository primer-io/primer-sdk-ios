//
//  NetworkingReportingServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
@testable import PrimerSDK
import XCTest

final class NetworkingReportingServiceTests: XCTestCase {

    var analyticsService: MockAnalyticsService!
    var networkReportingService: NetworkReportingService!

    override func setUpWithError() throws {
        analyticsService = MockAnalyticsService()
        networkReportingService = DefaultNetworkReportingService(analyticsService: analyticsService)
    }

    override func tearDownWithError() throws {
        networkReportingService = nil
        analyticsService = nil
    }

    func testRequestStartEventSent() throws {
        let expectation = XCTestExpectation(description: "Request start event sent")

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken,
                                                    requestParameters: nil)
        let request = try DefaultNetworkRequestFactory().request(for: endpoint, identifier: nil)

        // Assert
        analyticsService.onRecord = { events in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.eventType, .networkCall)
            XCTAssertNil(events.first?.analyticsUrl)
            XCTAssertTrue(events.first?.properties is NetworkCallEventProperties)

            let properties = events.first?.properties as! NetworkCallEventProperties
            XCTAssertEqual(properties.callType, .requestStart)
            expectation.fulfill()
        }

        networkReportingService.report(eventType: .requestStart(identifier: "id",
                                                                endpoint: endpoint,
                                                                request: request))

        wait(for: [expectation], timeout: 1)
    }

    func testRequestEndEventSent() throws {
        let expectation = XCTestExpectation(description: "Request end event sent")

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken,
                                                    requestParameters: nil)
        let responseMetadata = ResponseMetadataModel(responseUrl: nil, statusCode: 0, headers: nil)

        analyticsService.onRecord = { events in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.eventType, .networkCall)
            XCTAssertNil(events.first?.analyticsUrl)
            XCTAssertTrue(events.first?.properties is NetworkCallEventProperties)

            let properties = events.first?.properties as! NetworkCallEventProperties
            XCTAssertEqual(properties.callType, .requestEnd)
            expectation.fulfill()
        }

        networkReportingService.report(eventType: .requestEnd(identifier: "id",
                                                              endpoint: endpoint,
                                                              response: responseMetadata,
                                                              duration: 1000))

        wait(for: [expectation], timeout: 1)
    }

    func testNetworkConnectivityEventSent() throws {
        let expectation = XCTestExpectation(description: "Network connectivity event sent")

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken,
                                                    requestParameters: nil)

        analyticsService.onRecord = { events in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.eventType, .networkConnectivity)
            XCTAssertNil(events.first?.analyticsUrl)
            XCTAssertTrue(events.first?.properties is NetworkConnectivityEventProperties)

            let properties = events.first?.properties as! NetworkConnectivityEventProperties
            XCTAssertEqual(properties.networkType, "WIFI")
            expectation.fulfill()
        }

        networkReportingService.report(eventType: .networkConnectivity(endpoint: endpoint))

        wait(for: [expectation], timeout: 1)
    }

    func testAnalyticsEndpointEventsNotSent_checkoutTrack() throws {
        let expectation = XCTestExpectation(description: "Analytics endpoint events not sent")
        expectation.isInverted = true

        let url = URL(string: "https://analytics_url/checkout/track")!
        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: Mocks.decodedJWTToken, url: url, body: [])
        let request = try DefaultNetworkRequestFactory().request(for: endpoint, identifier: nil)

        analyticsService.onRecord = { events in
            XCTFail("Analytics endpoint events should not be sent")
            expectation.fulfill()
        }

        networkReportingService.report(eventType: .requestStart(identifier: "id", endpoint: endpoint, request: request))

        wait(for: [expectation], timeout: 1.0)
    }

    func testAnalyticsEndpointEventsNotSent_sdkLogs() throws {
        let expectation = XCTestExpectation(description: "Analytics endpoint events not sent")
        expectation.isInverted = true

        let url = URL(string: "https://analytics_url/sdk-logs")!
        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: Mocks.decodedJWTToken, url: url, body: [])
        let request = try DefaultNetworkRequestFactory().request(for: endpoint, identifier: nil)

        analyticsService.onRecord = { events in
            XCTFail("Analytics endpoint events should not be sent")
            expectation.fulfill()
        }

        networkReportingService.report(eventType: .requestStart(identifier: "id", endpoint: endpoint, request: request))

        wait(for: [expectation], timeout: 1.0)
    }
}
