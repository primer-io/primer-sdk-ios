//
//  MockPrimerAPIAnalyticsClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class MockPrimerAPIAnalyticsClient: PrimerAPIClientAnalyticsProtocol, @unchecked Sendable {

    var shouldSucceed: Bool = true

    var onSendAnalyticsEvent: (([PrimerSDK.Analytics.Event]?) -> Void)?

    var batches: [[Analytics.Event]] = []

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?, url: URL, body: [Analytics.Event]?, completion: @escaping ResponseHandler) {
        guard let body = body else {
            XCTFail(); return
        }
        batches.append(body)
        if shouldSucceed {
            completion(.success(.init(id: nil, result: nil)))
        } else {
            completion(.failure(PrimerError.unknown()))
        }
        self.onSendAnalyticsEvent?(body)
    }

    func sendAnalyticsEvents(clientToken: PrimerSDK.DecodedJWTToken?, url: URL, body: [PrimerSDK.Analytics.Event]?) async throws -> Analytics.Service.Response {
        guard let body = body else {
            XCTFail();
            throw PrimerError.unknown()
        }
        batches.append(body)
        self.onSendAnalyticsEvent?(body)
        if shouldSucceed {
            return .init(id: nil, result: nil)
        } else {
            throw PrimerError.unknown()
        }
    }
}
