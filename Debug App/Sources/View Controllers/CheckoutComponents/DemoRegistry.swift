//
//  DemoRegistry.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PrimerSDK

// MARK: - Demo Registry

/// Central registry for discovering and instantiating CheckoutComponents demos.
/// To add a new demo, create the demo file and register it in `allDemos`.
@available(iOS 15.0, *)
enum DemoRegistry {
    /// All registered demo types with their metadata and factory functions
    static let allDemos: [(metadata: DemoMetadata, factory: (DemoConfiguration) -> AnyView)] = [
        (DefaultCheckoutDemo.metadata, { config in AnyView(DefaultCheckoutDemo(configuration: config)) }),
        (CustomPaymentSelectionDemo.metadata, { config in AnyView(CustomPaymentSelectionDemo(configuration: config)) })
    ]

    /// Get all demo metadata for display in the examples list
    static var allMetadata: [DemoMetadata] {
        allDemos.map(\.metadata)
    }

    /// Create a demo view by its metadata ID
    /// - Parameters:
    ///   - id: The UUID of the demo metadata
    ///   - configuration: Configuration to pass to the demo
    /// - Returns: The instantiated demo view, or nil if not found
    static func createDemo(id: UUID, configuration: DemoConfiguration) -> AnyView? {
        guard let demo = allDemos.first(where: { $0.metadata.id == id }) else {
            return nil
        }
        return demo.factory(configuration)
    }
}
