//
//  DemoRegistry.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

@available(iOS 15.0, *)
enum DemoRegistry {
    static let allDemos: [(metadata: DemoMetadata, factory: (DemoConfiguration) -> AnyView)] = [
        (DefaultCheckoutDemo.metadata, { config in AnyView(DefaultCheckoutDemo(configuration: config)) }),
        (CustomPaymentSelectionDemo.metadata, { config in AnyView(CustomPaymentSelectionDemo(configuration: config)) })
    ]

    static var allMetadata: [DemoMetadata] {
        allDemos.map(\.metadata)
    }

    static func createDemo(id: UUID, configuration: DemoConfiguration) -> AnyView? {
        guard let demo = allDemos.first(where: { $0.metadata.id == id }) else {
            return nil
        }
        return demo.factory(configuration)
    }
}
