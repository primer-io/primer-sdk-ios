//
//  BanksAnalyticsConstant.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 15.11.2023.
//

import Foundation
enum BanksAnalyticsEvent: String {
    case start = "DefaultBanksComponent.start()"
    case updateCollectedData = "DefaultBanksComponent.updateCollectedData()"
    case submit = "DefaultBanksComponent.submit()"
}
