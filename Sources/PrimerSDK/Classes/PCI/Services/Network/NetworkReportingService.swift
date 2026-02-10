//
//  NetworkReportingService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerNetworking

enum NetworkEventType {
    case requestStart(identifier: String, endpoint: Endpoint, request: URLRequest)
    case requestEnd(identifier: String, endpoint: Endpoint, response: ResponseMetadata, duration: TimeInterval)
    case networkConnectivity(endpoint: Endpoint)

    var endpoint: Endpoint {
        switch self {
        case let .requestStart(_, endpoint, _),
             let .requestEnd(_, endpoint, _, _),
             let .networkConnectivity(endpoint):
            return endpoint
        }
    }
}

protocol NetworkReportingService: Sendable {
    func report(eventType: NetworkEventType)
}

private let disallowedTrackingPaths: [String] = [
    "/sdk-logs",
    "/checkout/track"
]

final class DefaultNetworkReportingService: NetworkReportingService {

    let analyticsService: AnalyticsServiceProtocol?

    init(analyticsService: AnalyticsServiceProtocol? = nil) {
        self.analyticsService = analyticsService
    }

    func report(eventType: NetworkEventType) {
        let event: Analytics.Event

        guard shouldReportNetworkEvents(for: eventType.endpoint) else { return }

        switch eventType {
        case let .requestStart(id, endpoint, request):
            event = Analytics.Event.networkCall(
                callType: .requestStart,
                id: id,
                url: request.url?.absoluteString ?? "Unknown",
                method: endpoint.method,
                errorBody: nil,
                responseCode: nil,
                duration: nil)
        case let .requestEnd(id, endpoint, response, duration):
            event = Analytics.Event.networkCall(
                callType: .requestEnd,
                id: id,
                url: response.responseUrl ?? "Unknown",
                method: endpoint.method,
                errorBody: nil,
                responseCode: response.statusCode,
                duration: duration
            )
        case .networkConnectivity:
            event = Analytics.Event.networkConnectivity()
        }

        Task { await (analyticsService ?? Analytics.Service.shared).fire(event: event) }
    }

    private func shouldReportNetworkEvents(for endpoint: Endpoint) -> Bool {
        guard let primerAPI = endpoint as? PrimerAPI else {
            return false
        }
        // Don't report events for polling requests
        guard primerAPI != PrimerAPI.poll(clientToken: nil, url: "") else {
            return false
        }
        guard let baseURL = primerAPI.baseURL, let url = URL(string: baseURL),
              !disallowedTrackingPaths.contains(url.path) else {
            return false
        }
        return true
    }
}
