//
//  ModifierApplication.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI

@available(iOS 15.0, *)
extension View {
    func applyPrimerModifier(_ modifier: PrimerModifier) -> some View {
        modifier.apply(to: self)
    }
}

// Environment helper for DI container and design tokens
@available(iOS 15.0, *)
extension View {
    func withPrimerEnvironment() -> some View {
        self
            .environment(\.diContainer, DIContainer.currentSync)
        // Note: Design tokens should be injected at the root level with actual tokens
        // This is just providing access to the DI container
    }
}
