//
//  DemoProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PrimerSDK

// MARK: - Demo Configuration

/// Configuration passed from parent to each demo
@available(iOS 15.0, *)
struct DemoConfiguration {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
}

// MARK: - Demo Metadata

/// Metadata for demo discovery and display in the examples list
struct DemoMetadata: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let tags: [String]
    let isCustom: Bool
}

// MARK: - Demo Protocol

/// Protocol for self-contained CheckoutComponents demos.
/// Each demo handles its own session creation, PrimerCheckout initialization, and UI.
@available(iOS 15.0, *)
protocol CheckoutComponentsDemo: View {
    /// Metadata for display in the examples list
    static var metadata: DemoMetadata { get }

    /// Initialize the demo with configuration from parent
    init(configuration: DemoConfiguration)
}
