//
//  KlarnaAnalyticsEvents.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

import Foundation

struct KlarnaAnalyticsEvents {
    static let createSessionMethod = "KlarnaComponent.start()"
    static let authorizeSessionMethod = "KlarnaComponent.submit"
    static let updateCollectedData = "KlarnaComponent.updateCollectedData()"
}
