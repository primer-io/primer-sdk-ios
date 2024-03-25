//
//  NetworkReportingService.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 15/03/2024.
//

import Foundation

enum NetworkEventType {
    case requestStart(identifier: String, endpoint: Endpoint, request: URLRequest)
    case requestEnd(identifier: String, endpoint: Endpoint, response: ResponseMetadata)
    case networkConnectivity
}

protocol NetworkReportingService {
    func report(eventType: NetworkEventType)
}

private let disallowedTrackingPaths: [String] = [
    "/sdk-logs",
    "/checkout/track"
]

class DefaultNetworkReportingService: NetworkReportingService {
    func report(eventType: NetworkEventType) {
        let event: Analytics.Event

        switch eventType {
        case .requestStart(let id, let endpoint, let request):
            guard shouldReportNetworkEvents(for: endpoint) else { return }
            event = Analytics.Event.networkCall(
                callType: .requestStart,
                id: id,
                url: request.url?.absoluteString ?? "Unknown",
                method: endpoint.method,
                errorBody: nil,
                responseCode: nil)
        case .requestEnd(let id, let endpoint, let response):
            guard shouldReportNetworkEvents(for: endpoint) else { return }
            event = Analytics.Event.networkCall(
                callType: .requestEnd,
                id: id,
                url: response.responseUrl ?? "Unknown",
                method: endpoint.method,
                errorBody: nil,
                responseCode: response.statusCode
            )
        case .networkConnectivity:
            event = Analytics.Event.networkConnectivity()
        }

        Analytics.Service.record(event: event)
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
