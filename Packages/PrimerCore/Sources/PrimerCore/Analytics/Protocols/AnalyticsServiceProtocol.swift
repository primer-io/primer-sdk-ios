//
//  AnalyticsServiceProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public protocol AnalyticsServiceProtocol: Actor {
    func record(events: [Analytics.Event]) async throws
    func fire(events: [Analytics.Event])
    func record(event: Analytics.Event) async throws
    func fire(event: Analytics.Event)
}
