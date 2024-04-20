//
//  MockPrimerAPIAnalyticsClient.swift
//  Debug App
//
//  Created by Jack Newcombe on 13/02/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class MockPrimerAPIAnalyticsClient: PrimerAPIClientAnalyticsProtocol {

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
            completion(.failure(PrimerError.generic(message: "", userInfo: nil, diagnosticsId: "")))
        }
        self.onSendAnalyticsEvent?(body)
    }
}
