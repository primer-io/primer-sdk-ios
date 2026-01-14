//
//  CheckoutHeaderView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Reusable header view for checkout screens with back button and optional right action button
@available(iOS 15.0, *)
struct CheckoutHeaderView: View {
    // MARK: - Configuration

    let showBackButton: Bool
    let onBack: () -> Void
    let rightButton: RightButtonConfig?

    @Environment(\.designTokens) private var tokens

    // MARK: - Right Button Configuration

    struct RightButtonConfig {
        let title: String
        let icon: String?
        let action: () -> Void
        let accessibilityIdentifier: String
        let accessibilityLabel: String

        static func closeButton(action: @escaping () -> Void) -> RightButtonConfig {
            RightButtonConfig(
                title: CheckoutComponentsStrings.cancelButton,
                icon: nil,
                action: action,
                accessibilityIdentifier: AccessibilityIdentifiers.Common.closeButton,
                accessibilityLabel: CheckoutComponentsStrings.a11yCancel
            )
        }

        static func editButton(action: @escaping () -> Void) -> RightButtonConfig {
            RightButtonConfig(
                title: CheckoutComponentsStrings.editButton,
                icon: "pencil",
                action: action,
                accessibilityIdentifier: AccessibilityIdentifiers.Common.editButton,
                accessibilityLabel: CheckoutComponentsStrings.a11yEdit
            )
        }

        static func doneButton(action: @escaping () -> Void) -> RightButtonConfig {
            RightButtonConfig(
                title: CheckoutComponentsStrings.doneButton,
                icon: "checkmark",
                action: action,
                accessibilityIdentifier: AccessibilityIdentifiers.Common.doneButton,
                accessibilityLabel: CheckoutComponentsStrings.a11yDone
            )
        }
    }

    // MARK: - Initialization

    init(
        showBackButton: Bool = true,
        onBack: @escaping () -> Void,
        rightButton: RightButtonConfig? = nil
    ) {
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.rightButton = rightButton
    }

    // MARK: - Body

    var body: some View {
        HStack {
            if showBackButton {
                makeBackButtonView()
            }

            Spacer()

            if let rightButton {
                makeRightButtonView(config: rightButton)
            }
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
    }

    private func makeBackButtonView() -> some View {
        Button(action: onBack) {
            HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                Image(systemName: "chevron.left")
                Text(CheckoutComponentsStrings.backButton)
            }
            .font(PrimerFont.bodyMedium(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        }
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.backButton,
            label: CheckoutComponentsStrings.a11yBack,
            traits: [.isButton]
        ))
    }

    private func makeRightButtonView(config: RightButtonConfig) -> some View {
        Button(action: config.action) {
            HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                if let icon = config.icon {
                    Image(systemName: icon)
                        .font(PrimerFont.caption(tokens: tokens))
                }
                Text(config.title)
                    .font(PrimerFont.titleLarge(tokens: tokens))
            }
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        }
        .accessibility(config: AccessibilityConfiguration(
            identifier: config.accessibilityIdentifier,
            label: config.accessibilityLabel,
            traits: [.isButton]
        ))
    }
}
