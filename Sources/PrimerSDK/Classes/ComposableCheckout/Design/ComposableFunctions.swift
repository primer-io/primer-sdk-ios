//
//  ComposableFunctions.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI

/// Android-style composable function patterns for iOS
@available(iOS 15.0, *)
public struct Composable {

    /// Creates a more Android-like function signature pattern
    /// This allows us to write: Composable.PrimerCardNumberInput(modifier, ...) { }
    public struct PrimerCardNumberInput {
        public static func callAsFunction(
            modifier: PrimerModifier = PrimerModifier(),
            label: String? = nil,
            placeholder: String? = nil,
            onValueChange: @escaping (String) -> Void = { _ in }
        ) -> some View {
            PrimerComponents.PrimerCardNumberInput(
                modifier: modifier,
                label: label,
                placeholder: placeholder,
                onValueChange: onValueChange
            )
        }
    }

    public struct PrimerCvvInput {
        public static func callAsFunction(
            modifier: PrimerModifier = PrimerModifier(),
            label: String? = nil,
            placeholder: String? = nil,
            onValueChange: @escaping (String) -> Void = { _ in }
        ) -> some View {
            PrimerComponents.PrimerCvvInput(
                modifier: modifier,
                label: label,
                placeholder: placeholder,
                onValueChange: onValueChange
            )
        }
    }

    public struct PrimerSubmitButton {
        public static func callAsFunction(
            modifier: PrimerModifier = PrimerModifier(),
            text: String = "Submit",
            enabled: Bool = true,
            onClick: @escaping () -> Void = { }
        ) -> some View {
            PrimerComponents.PrimerSubmitButton(
                modifier: modifier,
                text: text,
                enabled: enabled,
                onClick: onClick
            )
        }
    }

    // This creates a syntax closer to Android:
    // Composable.PrimerCardNumberInput(modifier) instead of PrimerComponents.PrimerCardNumberInput(modifier:)
}

// MARK: - Global Functions (Even More Android-Like)

// swiftlint:disable identifier_name
// Note: Function names intentionally use uppercase to match Android's API exactly

/// Even more Android-like global functions
@available(iOS 15.0, *)
public func PrimerCardNumberInput(
    modifier: PrimerModifier = PrimerModifier(),
    label: String? = nil,
    placeholder: String? = nil,
    onValueChange: @escaping (String) -> Void = { _ in }
) -> some View {
    PrimerComponents.PrimerCardNumberInput(
        modifier: modifier,
        label: label,
        placeholder: placeholder,
        onValueChange: onValueChange
    )
}

@available(iOS 15.0, *)
public func PrimerCvvInput(
    modifier: PrimerModifier = PrimerModifier(),
    label: String? = nil,
    placeholder: String? = nil,
    onValueChange: @escaping (String) -> Void = { _ in }
) -> some View {
    PrimerComponents.PrimerCvvInput(
        modifier: modifier,
        label: label,
        placeholder: placeholder,
        onValueChange: onValueChange
    )
}

@available(iOS 15.0, *)
public func PrimerSubmitButton(
    modifier: PrimerModifier = PrimerModifier(),
    text: String = "Submit",
    enabled: Bool = true,
    onClick: @escaping () -> Void = { }
) -> some View {
    PrimerComponents.PrimerSubmitButton(
        modifier: modifier,
        text: text,
        enabled: enabled,
        onClick: onClick
    )
}

// swiftlint:enable identifier_name

// This enables the most Android-like syntax:
// PrimerCardNumberInput(modifier)
// instead of PrimerComponents.PrimerCardNumberInput(modifier:)
