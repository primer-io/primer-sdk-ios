//
//  BanksAnalyticsEvent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
enum BanksAnalyticsEvent: String {
    case start = "DefaultBanksComponent.start()"
    case updateCollectedData = "DefaultBanksComponent.updateCollectedData()"
    case submit = "DefaultBanksComponent.submit()"
}
