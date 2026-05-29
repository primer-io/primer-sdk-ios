//
//  AnalyticsServiceProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) public protocol AnalyticsServiceProtocol: Actor {
    func record(events: [any AnalyticsEvent]) async throws
    func fire(events: [any AnalyticsEvent])
    func record(event: any AnalyticsEvent) async throws
    func fire(event: any AnalyticsEvent)
}
