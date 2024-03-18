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

class DefaultNetworkReportingService: NetworkReportingService {
    func report(eventType: NetworkEventType) {
        let event: Analytics.Event

        switch eventType {
        case .requestStart(let id, let endpoint, let request):
            event = Analytics.Event.networkCall(
                callType: .requestStart,
                id: id,
                url: request.url?.absoluteString ?? "Unknown",
                method: endpoint.method,
                errorBody: nil,
                responseCode: nil)
        case .requestEnd(let id, let endpoint, let response):
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
            break
        }

        Analytics.Service.record(event: event)
    }
}
