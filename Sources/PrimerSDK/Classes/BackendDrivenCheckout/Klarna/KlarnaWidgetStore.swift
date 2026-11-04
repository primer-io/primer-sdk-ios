//
//  KlarnaWidgetStore.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
final class KlarnaWidgetStore {
    static let shared = KlarnaWidgetStore()
    private var widgets: [String: KlarnaWidgetContainerView] = [:]
    private var latestCategory: String?

    private init() {
        // Use the shared instance
    }

    func set(_ widget: KlarnaWidgetContainerView, for category: String) {
        widgets[category] = widget
        latestCategory = category
    }

    func widget(for category: String?) -> KlarnaWidgetContainerView? {
        (category ?? latestCategory).flatMap { widgets[$0] }
    }
}
#endif
