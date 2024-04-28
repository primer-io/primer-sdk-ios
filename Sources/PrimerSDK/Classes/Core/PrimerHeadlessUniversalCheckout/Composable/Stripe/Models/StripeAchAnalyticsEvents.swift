//
//  StripeAchAnalyticsEvents.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

struct StripeAnalyticsEvents {
    static let createSessionMethod = "StripeAchUserDetailsComponent.start()"
    static let authorizeSessionMethod = "StripeAchUserDetailsComponent.submit"
    static let updateCollectedData = "StripeAchUserDetailsComponent.updateCollectedData()"
}
