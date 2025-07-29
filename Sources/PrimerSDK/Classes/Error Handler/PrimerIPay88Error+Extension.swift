//
//  PrimerIPay88Error+Extension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

#if canImport(PrimerIPay88MYSDK)
import PrimerIPay88MYSDK
extension PrimerIPay88Error: PrimerErrorProtocol {
    var exposedError: Error {
        self
    }

    var errorId: String {
        switch self {
        case .iPay88Error:
            return "ipay88"
        }
    }

    var info: [String: Any]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]

        switch self {
        case .iPay88Error(let description, let userInfo):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            tmpUserInfo["description"] = description
            tmpUserInfo["diagnosticsId"] = self.diagnosticsId
        }

        return tmpUserInfo
    }

    public var errorDescription: String? {
        switch self {
        case .iPay88Error(let description, _):
            return "[\(errorId)] iPay88 failed with error \(description) (diagnosticsId: \(self.diagnosticsId))"
        }
    }

    var analyticsContext: [String: Any] {
        [
            AnalyticsContextKeys.errorId: errorId,
            AnalyticsContextKeys.paymentMethodType: PrimerPaymentMethodType.iPay88Card.rawValue
        ]
    }

    var diagnosticsId: String {
        return UUID().uuidString
    }
}
#endif
