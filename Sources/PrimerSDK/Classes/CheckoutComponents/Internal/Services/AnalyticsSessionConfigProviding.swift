//
//  AnalyticsSessionConfigProviding.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol AnalyticsSessionConfigProviding {
    func makeAnalyticsSessionConfig(
        checkoutSessionId: String,
        clientToken: String,
        sdkVersion: String
    ) -> AnalyticsSessionConfig?
}
