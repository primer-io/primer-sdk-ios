//
//  NetworkingReportingServiceTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 27/03/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class MockAnalyticsService: AnalyticsServiceProtocol {

    var events: [Analytics.Event] = []

    var onRecord: (([Analytics.Event]) -> Void)?

    func record(events: [Analytics.Event]) -> Promise<Void> {
        self.events.append(contentsOf: events)
        onRecord?(events)
        return Promise.fulfilled(())
    }
}

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

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken,
                                                    requestParameters: nil)
        let request = try DefaultNetworkRequestFactory().request(for: endpoint)

        networkReportingService.report(eventType: .requestStart(identifier: "id", 
                                                                endpoint: endpoint,
                                                                request: request))

        XCTAssertEqual(analyticsService.events.count, 1)

        let event = analyticsService.events.first!
        XCTAssertEqual(event.eventType, .networkCall)
        XCTAssertNil(event.analyticsUrl)
        XCTAssertTrue(event.properties is NetworkCallEventProperties)

        let properties = event.properties as! NetworkCallEventProperties
        XCTAssertEqual(properties.callType, .requestStart)
    }

    func testRequestEndEventSent() throws {

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken,
                                                    requestParameters: nil)
        let responseMetadata = ResponseMetadataModel(responseUrl: nil, statusCode: 0, headers: nil)

        networkReportingService.report(eventType: .requestEnd(identifier: "id",
                                                              endpoint: endpoint,
                                                              response: responseMetadata))

        XCTAssertEqual(analyticsService.events.count, 1)

        let event = analyticsService.events.first!
        XCTAssertEqual(event.eventType, .networkCall)
        XCTAssertNil(event.analyticsUrl)
        XCTAssertTrue(event.properties is NetworkCallEventProperties)

        let properties = event.properties as! NetworkCallEventProperties
        XCTAssertEqual(properties.callType, .requestEnd)
    }

    func testNetworkConnectivityEventSent() throws {

        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken,
                                                    requestParameters: nil)

        networkReportingService.report(eventType: .networkConnectivity(endpoint: endpoint))

        XCTAssertEqual(analyticsService.events.count, 1)

        let event = analyticsService.events.first!
        XCTAssertEqual(event.eventType, .networkConnectivity)
        XCTAssertNil(event.analyticsUrl)
        XCTAssertTrue(event.properties is NetworkConnectivityEventProperties)

        let properties = event.properties as! NetworkConnectivityEventProperties
        XCTAssertEqual(properties.networkType, .wifi)
    }

    func testAnalyticsEndpointEventsNotSent_checkoutTrack() throws {

        let url = URL(string: "https://analytics_url/checkout/track")!
        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: Mocks.decodedJWTToken, url: url, body: [])
        let request = try DefaultNetworkRequestFactory().request(for: endpoint)

        networkReportingService.report(eventType: .requestStart(identifier: "id", endpoint: endpoint, request: request))

        XCTAssertEqual(analyticsService.events.count, 0)
    }

    func testAnalyticsEndpointEventsNotSent_sdkLogs() throws {

        let url = URL(string: "https://analytics_url/sdk-logs")!
        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: Mocks.decodedJWTToken, url: url, body: [])
        let request = try DefaultNetworkRequestFactory().request(for: endpoint)

        networkReportingService.report(eventType: .requestStart(identifier: "id", endpoint: endpoint, request: request))

        XCTAssertEqual(analyticsService.events.count, 0)
    }
}
