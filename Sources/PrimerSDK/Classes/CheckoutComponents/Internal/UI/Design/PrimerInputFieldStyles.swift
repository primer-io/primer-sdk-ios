//
//  PrimerInputFieldStyles.swift
//  PrimerSDK - CheckoutComponents
//
//  Composite modifiers for input field styling
//

import SwiftUI

// MARK: - Standalone Helper Functions

/// Returns appropriate border color based on field state
/// - Parameters:
///   - errorMessage: Optional error message (determines error state)
///   - isFocused: Whether the field is focused
///   - styling: Optional custom styling
///   - tokens: Design tokens
/// - Returns: Appropriate border color for current state
@available(iOS 15.0, *)
func primerInputBorderColor(
    errorMessage: String?,
    isFocused: Bool,
    styling: PrimerFieldStyling?,
    tokens: DesignTokens?
) -> Color {
    if let errorMessage = errorMessage, !errorMessage.isEmpty {
        return styling?.errorBorderColor ?? PrimerCheckoutColors.borderError(tokens: tokens)
    } else if isFocused {
        return styling?.focusedBorderColor ?? PrimerCheckoutColors.borderFocus(tokens: tokens)
    } else {
        return styling?.borderColor ?? PrimerCheckoutColors.borderDefault(tokens: tokens)
    }
}

// MARK: - Input Field Styling Modifiers

@available(iOS 15.0, *)
extension View {
    /// Applies label styling (font + color)
    /// Merges: font(...) + foregroundColor(...)
    func primerLabelStyle(styling: PrimerFieldStyling?, tokens: DesignTokens?) -> some View {
        self
            .font(styling?.labelFont ?? PrimerFont.bodySmall(tokens: tokens))
            .foregroundColor(styling?.labelColor ?? PrimerCheckoutColors.textSecondary(tokens: tokens))
    }

    /// Applies error message styling (font + color + padding + opacity)
    /// Merges: font(...) + foregroundColor(...) + padding(...) + opacity(...)
    func primerErrorMessageStyle(tokens: DesignTokens?) -> some View {
        self
            .font(PrimerFont.bodySmall(tokens: tokens))
            .foregroundColor(PrimerCheckoutColors.textNegative(tokens: tokens))
            .padding(.top, PrimerSpacing.xsmall(tokens: tokens))
    }

    /// Applies input field padding with smart error handling
    /// Merges: padding(.leading, ...) + padding(.trailing, ...) + padding(.vertical, ...)
    func primerInputPadding(
        styling: PrimerFieldStyling?,
        tokens: DesignTokens?,
        errorPresent: Bool
    ) -> some View {
        self
            .padding(.leading, styling?.padding?.leading ?? PrimerSpacing.large(tokens: tokens))
            .padding(.trailing, errorPresent ?
                PrimerSize.xxlarge(tokens: tokens) + PrimerSpacing.large(tokens: tokens) :
                (styling?.padding?.trailing ?? PrimerSpacing.large(tokens: tokens)))
            .padding(.vertical, styling?.padding?.top ?? PrimerSpacing.medium(tokens: tokens))
    }

    /// Applies error icon styling (size + color + padding)
    /// Merges: frame(...) + foregroundColor(...) + padding(...)
    /// Note: If used on Image, call .resizable() before this modifier
    func primerErrorIconStyle(tokens: DesignTokens?) -> some View {
        let size = PrimerSize.medium(tokens: tokens)
        return self
            .frame(width: size, height: size)
            .foregroundColor(PrimerCheckoutColors.iconNegative(tokens: tokens))
            .padding(Edge.Set.trailing, PrimerSpacing.medium(tokens: tokens))
    }

    /// Applies input field height
    func primerInputFieldHeight(styling: PrimerFieldStyling?, tokens: DesignTokens?) -> some View {
        self.frame(height: styling?.fieldHeight ?? PrimerSize.xxlarge(tokens: tokens))
    }

    /// View extension wrapper for primerInputBorderColor
    /// - Parameters:
    ///   - errorMessage: Optional error message (determines error state)
    ///   - isFocused: Whether the field is focused
    ///   - styling: Optional custom styling
    ///   - tokens: Design tokens
    /// - Returns: Appropriate border color for current state
    func primerInputBorderColor(
        errorMessage: String?,
        isFocused: Bool,
        styling: PrimerFieldStyling?,
        tokens: DesignTokens?
    ) -> Color {
        return PrimerSDK.primerInputBorderColor(
            errorMessage: errorMessage,
            isFocused: isFocused,
            styling: styling,
            tokens: tokens
        )
    }

    /// Applies input field border with background (replaces RoundedRectangle fill + overlay pattern)
    /// More efficient than creating two separate shapes
    func primerInputFieldBorder(
        cornerRadius: CGFloat,
        backgroundColor: Color,
        borderColor: Color,
        borderWidth: CGFloat,
        animationValue: Bool? = nil
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderColor, lineWidth: borderWidth)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                )
                .animation(animationValue != nil ? AnimationConstants.focusAnimation : nil, value: animationValue)
        )
    }

    /// Applies subtle border for badges and icons
    func primerSubtleBorder(
        cornerRadius: CGFloat,
        tokens: DesignTokens?
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(PrimerCheckoutColors.borderDefault(tokens: tokens), lineWidth: PrimerBorderWidth.thin)
        )
    }

    /// Applies dropdown shadow using semantic tokens
    func primerDropdownShadow(tokens: DesignTokens?) -> some View {
        self.shadow(
            color: PrimerCheckoutColors.borderDefault(tokens: tokens),
            radius: PrimerRadius.small(tokens: tokens),
            x: 0,
            y: PrimerSpacing.xxsmall(tokens: tokens)
        )
    }
}
