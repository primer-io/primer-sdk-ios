//
//  BanksAnalyticsConstant.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 15.11.2023.
//

import Foundation
enum BanksAnalyticsEvent: String {
    case start = "BanksComponent.start()"
    case updateCollectedData = "BanksComponent.updateCollectedData()"
    case submit = "BanksComponent.submit()"
}
