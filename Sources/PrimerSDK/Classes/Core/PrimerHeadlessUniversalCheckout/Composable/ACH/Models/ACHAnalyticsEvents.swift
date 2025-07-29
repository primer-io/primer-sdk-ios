//
//  ACHAnalyticsEvents.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol ACHAnalyticsEventsRecordable {
    var startMethod: String { get }
    var submitMethod: String { get }
    var updateCollectedData: String { get }
}

enum ACHAnalyticsEvents: ACHAnalyticsEventsRecordable {
    case stripe

    var startMethod: String {
        switch self {
        case .stripe:
            return "StripeAchUserDetailsComponent.start()"
        }
    }

    var submitMethod: String {
        switch self {
        case .stripe:
            return "StripeAchUserDetailsComponent.submit()"
        }
    }

    var updateCollectedData: String {
        switch self {
        case .stripe:
            return "StripeAchUserDetailsComponent.updateCollectedData()"
        }
    }
}
