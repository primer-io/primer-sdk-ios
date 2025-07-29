//
//  PrimerKlarnaError+Extension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
extension PrimerKlarnaError: PrimerErrorProtocol {
    typealias InfoType = [String: String]
    var exposedError: Error {
        self
    }

    var info: InfoType? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]

        switch self {
        case .userNotApproved(let userInfo),
             .klarnaSdkError(_, let userInfo):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            tmpUserInfo["diagnosticsId"] = self.diagnosticsId
        default: break
        }

        return tmpUserInfo
    }

    var errorId: String {
        switch self {
        case .userNotApproved:
            return "klarna-user-not-approved"
        case .klarnaSdkError:
            return "klarna-sdk-error"
        default:
            return "klarna-unknown-error-id"
        }
    }

    var analyticsContext: [String: Any] {
        [
            AnalyticsContextKeys.errorId: errorId,
            AnalyticsContextKeys.paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
        ]
    }

    var diagnosticsId: String {
        return UUID().uuidString
    }
}
#endif
