//
//  AnalyticsEnvironment.swift
//  PrimerSDK
//
//  Created by CheckoutComponents Analytics
//

import Foundation

/// Analytics environment enumeration matching Primer backend environments
public enum AnalyticsEnvironment: String, Codable {
    case dev = "DEV"
    case staging = "STAGING"
    case sandbox = "SANDBOX"
    case production = "PRODUCTION"
}
