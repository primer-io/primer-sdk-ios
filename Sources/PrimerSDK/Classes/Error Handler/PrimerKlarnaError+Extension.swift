//
//  PrimerKlarnaError+Extension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK

extension PrimerKlarnaError: PrimerErrorProtocol {
    typealias InfoType = [String: String]
    public var exposedError: Error {
        self
    }

    public var errorId: String {
        switch self {
        case .userNotApproved:
            return "klarna-user-not-approved"
        case .klarnaSdkError:
            return "klarna-sdk-error"
        default:
            return "klarna-unknown-error-id"
        }
    }

    public var analyticsContext: [String: Any] {
        [
            AnalyticsContextKeys.errorId: errorId,
            AnalyticsContextKeys.paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
        ]
    }

    public var diagnosticsId: String {
        UUID().uuidString
    }
}
#endif
