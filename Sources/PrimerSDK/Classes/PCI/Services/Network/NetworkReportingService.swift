//
//  NetworkReportingService.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 15/03/2024.
//

import Foundation

enum NetworkEventType {
    case requestStart(identifier: String, endpoint: Endpoint, request: URLRequest)
    case requestEnd(identifier: String, endpoint: Endpoint, response: ResponseMetadata, duration: TimeInterval)
    case networkConnectivity(endpoint: Endpoint)

    var endpoint: Endpoint {
        switch self {
        case .requestStart(_, let endpoint, _),
             .requestEnd(_, let endpoint, _, _),
             .networkConnectivity(let endpoint):
            return endpoint
        }
    }
}

protocol NetworkReportingService {
    func report(eventType: NetworkEventType)
}

private let disallowedTrackingPaths: [String] = [
    "/sdk-logs",
    "/checkout/track"
]

class DefaultNetworkReportingService: NetworkReportingService {

    let analyticsService: AnalyticsServiceProtocol?

    init(analyticsService: AnalyticsServiceProtocol? = nil) {
        self.analyticsService = analyticsService
    }

    func report(eventType: NetworkEventType) {
        let event: Analytics.Event

        guard shouldReportNetworkEvents(for: eventType.endpoint) else { return }

        switch eventType {
        case .requestStart(let id, let endpoint, let request):
            event = Analytics.Event.networkCall(
                callType: .requestStart,
                id: id,
                url: request.url?.absoluteString ?? "Unknown",
                method: endpoint.method,
                errorBody: nil,
                responseCode: nil,
                duration: nil)
        case .requestEnd(let id, let endpoint, let response, let duration):
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

        (analyticsService ?? Analytics.Service.shared).record(event: event)
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
