//
//  AnalyticsEventProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

protocol AnalyticsEvent: Sendable {
    var analyticsUrl: String? { get }
    var localId: String { get }
    var createdAt: Int { get }
}

extension Analytics.Event: AnalyticsEvent {}
