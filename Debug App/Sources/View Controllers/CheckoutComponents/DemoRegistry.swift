//
//  DemoRegistry.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

@available(iOS 15.0, *)
enum DemoRegistry {
    typealias DemoEntry = (metadata: DemoMetadata, factory: (DemoConfiguration) -> AnyView)

    static let allDemos: [DemoEntry] = flowDemos + themeDemos + utilityDemos

    static var allMetadata: [DemoMetadata] {
        allDemos.map(\.metadata)
    }

    /// Demos grouped by category, in category declaration order, skipping empty categories.
    static var sections: [(category: DemoCategory, demos: [DemoMetadata])] {
        DemoCategory.allCases.compactMap { category in
            let demos = allMetadata.filter { $0.category == category }
            return demos.isEmpty ? nil : (category, demos)
        }
    }

    static func createDemo(id: UUID, configuration: DemoConfiguration) -> AnyView? {
        guard let demo = allDemos.first(where: { $0.metadata.id == id }) else {
            return nil
        }
        return demo.factory(configuration)
    }

    private static let flowDemos: [DemoEntry] = [
        // Core
        (DefaultCheckoutDemo.metadata, { AnyView(DefaultCheckoutDemo(configuration: $0)) }),
        (InlineCheckoutDemo.metadata, { AnyView(InlineCheckoutDemo(configuration: $0)) }),
        (InlineCardFormDemo.metadata, { AnyView(InlineCardFormDemo(configuration: $0)) }),
        (CardFormSheetDemo.metadata, { AnyView(CardFormSheetDemo(configuration: $0)) }),
        (CustomCardFormDemo.metadata, { AnyView(CustomCardFormDemo(configuration: $0)) }),
        (BeforePaymentGateDemo.metadata, { AnyView(BeforePaymentGateDemo(configuration: $0)) }),
        // Payment method lists
        (PaymentMethodListOnlyDemo.metadata, { AnyView(PaymentMethodListOnlyDemo(configuration: $0)) }),
        (CustomPaymentMethodsDemo.metadata, { AnyView(CustomPaymentMethodsDemo(configuration: $0)) }),
        (CustomGridPaymentMethodsDemo.metadata, { AnyView(CustomGridPaymentMethodsDemo(configuration: $0)) }),
        (RadioSelectionDemo.metadata, { AnyView(RadioSelectionDemo(configuration: $0)) }),
        // Vault
        (VaultManagementDemo.metadata, { AnyView(VaultManagementDemo(configuration: $0)) }),
        (VaultedPaymentMethodsDemo.metadata, { AnyView(VaultedPaymentMethodsDemo(configuration: $0)) }),
        (VaultModeInlineDemo.metadata, { AnyView(VaultModeInlineDemo(configuration: $0)) }),
        (DynamicVaultDemo.metadata, { AnyView(DynamicVaultDemo(configuration: $0)) }),
        // Navigation & flows
        (MerchantNavigationDemo.metadata, { AnyView(MerchantNavigationDemo(configuration: $0)) }),
        (CustomResultScreensDemo.metadata, { AnyView(CustomResultScreensDemo(configuration: $0)) }),
        (CustomNavigationDemo.metadata, { AnyView(CustomNavigationDemo(configuration: $0)) })
    ]

    private static let themeDemos: [DemoEntry] = ThemeDemos.entries.map { entry in
        (metadata: entry.metadata,
         factory: { AnyView(ThemedManagedDemo(configuration: $0, title: entry.metadata.name, theme: entry.theme)) })
    }

    private static let utilityDemos: [DemoEntry] = [
        (RefreshClientSessionDemo.metadata, { AnyView(RefreshClientSessionDemo(configuration: $0)) })
    ]
}
