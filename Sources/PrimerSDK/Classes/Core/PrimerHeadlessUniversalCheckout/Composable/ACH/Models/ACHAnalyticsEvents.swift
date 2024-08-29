//
//  ACHAnalyticsEvents.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

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
