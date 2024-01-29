//
//  PrimerIPay88Error+Extension.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 06/12/23.
//

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
