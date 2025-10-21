//
//  AnalyticsSessionConfigProviding.swift
//  PrimerSDK
//
//  Created by Checkout Components Analytics Provider.
//

import Foundation

protocol AnalyticsSessionConfigProviding {
    func makeAnalyticsSessionConfig(
        checkoutSessionId: String,
        clientToken: String,
        sdkVersion: String
    ) -> AnalyticsSessionConfig?
}
