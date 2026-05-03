//
//  PrimerKlarnaError+Extension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK

extension PrimerKlarnaError: PrimerErrorProtocol {
    typealias InfoType = [String: String]
    var exposedError: Error {
        self
    }

    var errorId: String {
        switch self {
        case .userNotApproved:
            "klarna-user-not-approved"
        case .klarnaSdkError:
            "klarna-sdk-error"
        default:
            "klarna-unknown-error-id"
        }
    }

    var analyticsContext: [String: Any] {
        [
            AnalyticsContextKeys.errorId: errorId,
            AnalyticsContextKeys.paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
        ]
    }

    var diagnosticsId: String {
        UUID().uuidString
    }

    var isReportable: Bool { true }
}
#endif
