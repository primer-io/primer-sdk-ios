//
//  PrimerModifierExtractor.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Claude on 23.7.25.
//

import SwiftUI

/// Unified utility for extracting values from PrimerModifier chains.
/// This eliminates code duplication across input field components and provides
/// consistent modifier value extraction with proper hierarchy (PrimerModifier → Design Tokens → Default).
@available(iOS 15.0, *)
internal struct PrimerModifierExtractor {
    
    // MARK: - Corner Radius Extraction
    
    /// Extracts corner radius from PrimerModifier with fallback hierarchy
    /// 1. PrimerModifier value (highest priority)
    /// 2. Design tokens value (merchant settings)
    /// 3. Default value (lowest priority)
    static func extractCornerRadius(
        from modifier: PrimerModifier,
        tokens: DesignTokens?,
        defaultValue: CGFloat = 8
    ) -> CGFloat {
        // 1. Check if PrimerModifier has cornerRadius set (highest priority)
        if let modifierRadius = extractCornerRadiusFromModifier(modifier) {
            return modifierRadius
        }
        
        // 2. Fall back to design tokens (merchant settings)
        if let tokenRadius = tokens?.primerRadiusMedium {
            return tokenRadius
        }
        
        // 3. Final fallback to default value
        return defaultValue
    }
    
    /// Extracts corner radius value directly from PrimerModifier chain
    static func extractCornerRadiusFromModifier(_ modifier: PrimerModifier) -> CGFloat? {
        // Look for cornerRadius modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .cornerRadius(let radius) = modifierType {
                return radius
            }
        }
        return nil
    }
    
    // MARK: - Background Color Extraction
    
    /// Extracts background color from PrimerModifier with gradient-aware fallback hierarchy
    /// 1. PrimerModifier value (highest priority) - but only if no gradient is present
    /// 2. Design tokens value (merchant settings)
    /// 3. Default value (lowest priority)
    /// Note: Returns nil when gradient background is present to let full modifier chain handle it
    static func extractBackgroundColor(
        from modifier: PrimerModifier,
        tokens: DesignTokens?,
        defaultValue: Color = Color.white
    ) -> Color? {
        // 1. If gradient is present, return nil to let the full modifier chain handle it
        if hasBackgroundGradient(modifier) {
            return nil
        }
        
        // 2. Check if PrimerModifier has solid background set (highest priority)
        if let modifierBackground = extractBackgroundFromModifier(modifier) {
            return modifierBackground
        }
        
        // 3. Fall back to design tokens (merchant settings)
        if let tokenBackground = tokens?.primerColorBackground {
            return tokenBackground
        }
        
        // 4. Final fallback to default value
        return defaultValue
    }
    
    /// Extracts background color value directly from PrimerModifier chain
    static func extractBackgroundFromModifier(_ modifier: PrimerModifier) -> Color? {
        // Look for background modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .background(let color) = modifierType {
                return color
            }
        }
        return nil
    }
    
    /// Checks if PrimerModifier contains a gradient background
    static func hasBackgroundGradient(_ modifier: PrimerModifier) -> Bool {
        // Look for backgroundGradient modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .backgroundGradient = modifierType {
                return true
            }
        }
        return false
    }
    
    // MARK: - Border Color Extraction
    
    /// Extracts border color from PrimerModifier with fallback hierarchy
    /// 1. PrimerModifier value (highest priority)
    /// 2. Design tokens value (merchant settings)
    /// 3. Default value (lowest priority)
    static func extractBorderColor(
        from modifier: PrimerModifier,
        tokens: DesignTokens?,
        defaultValue: Color = Color.gray
    ) -> Color? {
        // Look for border modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .border(let color, _) = modifierType {
                return color
            }
        }
        return nil
    }
    
    // MARK: - Border Width Extraction
    
    /// Extracts border width from PrimerModifier with fallback hierarchy
    static func extractBorderWidth(
        from modifier: PrimerModifier,
        defaultValue: CGFloat = 1
    ) -> CGFloat? {
        // Look for border modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .border(_, let width) = modifierType {
                return width
            }
        }
        return nil
    }
    
    // MARK: - Opacity Extraction
    
    /// Extracts opacity from PrimerModifier with fallback hierarchy
    static func extractOpacity(
        from modifier: PrimerModifier,
        defaultValue: Double = 1.0
    ) -> Double {
        // Look for opacity modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .opacity(let opacity) = modifierType {
                return opacity
            }
        }
        return defaultValue
    }
    
    // MARK: - Font Extraction
    
    /// Extracts font from PrimerModifier with fallback hierarchy
    static func extractFont(
        from modifier: PrimerModifier,
        tokens: DesignTokens?,
        defaultValue: Font = .system(size: 16, weight: .regular)
    ) -> Font {
        // Look for font modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .font(let font) = modifierType {
                return font
            }
        }
        return defaultValue
    }
    
    // MARK: - Foreground Color Extraction
    
    /// Extracts foreground color from PrimerModifier with fallback hierarchy
    static func extractForegroundColor(
        from modifier: PrimerModifier,
        tokens: DesignTokens?,
        defaultValue: Color = Color.primary
    ) -> Color {
        // Look for foregroundColor modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .foregroundColor(let color) = modifierType {
                return color
            }
        }
        return defaultValue
    }
    
    // MARK: - Padding Extraction
    
    /// Extracts padding from PrimerModifier
    static func extractPadding(from modifier: PrimerModifier) -> EdgeInsets? {
        // Look for padding modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .padding(let insets) = modifierType {
                return insets
            }
        }
        return nil
    }
    
    // MARK: - Animation Extraction
    
    /// Extracts animation from PrimerModifier
    static func extractAnimation(from modifier: PrimerModifier) -> Animation? {
        // Look for animation modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .animation(let animation) = modifierType {
                return animation
            }
        }
        return nil
    }
    
    // MARK: - Disabled State Extraction
    
    /// Extracts disabled state from PrimerModifier
    static func extractDisabled(
        from modifier: PrimerModifier,
        defaultValue: Bool = false
    ) -> Bool {
        // Look for disabled modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .disabled(let disabled) = modifierType {
                return disabled
            }
        }
        return defaultValue
    }
    
    // MARK: - Loading State Extraction
    
    /// Extracts loading state from PrimerModifier
    static func extractLoading(
        from modifier: PrimerModifier,
        defaultValue: Bool = false
    ) -> Bool {
        // Look for loading modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .loading(let loading) = modifierType {
                return loading
            }
        }
        return defaultValue
    }
    
    // MARK: - Selected State Extraction
    
    /// Extracts selected state from PrimerModifier
    static func extractSelected(
        from modifier: PrimerModifier,
        defaultValue: Bool = false
    ) -> Bool {
        // Look for selected modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .selected(let selected) = modifierType {
                return selected
            }
        }
        return defaultValue
    }
    
    // MARK: - Pressed State Extraction
    
    /// Extracts pressed state from PrimerModifier
    static func extractPressed(
        from modifier: PrimerModifier,
        defaultValue: Bool = false
    ) -> Bool {
        // Look for pressed modifier in the modifier chain
        for modifierType in modifier.modifiers {
            if case .pressed(let pressed) = modifierType {
                return pressed
            }
        }
        return defaultValue
    }
    
    // MARK: - Convenience Methods
    
    /// Creates computed property patterns for easy integration in input fields
    struct ComputedProperties {
        let modifier: PrimerModifier
        let tokens: DesignTokens?
        
        /// Corner radius with proper hierarchy
        var effectiveCornerRadius: CGFloat {
            PrimerModifierExtractor.extractCornerRadius(from: modifier, tokens: tokens)
        }
        
        /// Background color with proper hierarchy - returns white fallback when gradient is present
        var effectiveBackgroundColor: Color {
            return PrimerModifierExtractor.extractBackgroundColor(from: modifier, tokens: tokens) ?? .white
        }
        
        /// Opacity with proper hierarchy
        var effectiveOpacity: Double {
            PrimerModifierExtractor.extractOpacity(from: modifier)
        }
        
        /// Font with proper hierarchy
        var effectiveFont: Font {
            PrimerModifierExtractor.extractFont(from: modifier, tokens: tokens)
        }
        
        /// Foreground color with proper hierarchy
        var effectiveForegroundColor: Color {
            PrimerModifierExtractor.extractForegroundColor(from: modifier, tokens: tokens)
        }
    }
    
    /// Creates a ComputedProperties instance for easier integration
    static func computedProperties(
        modifier: PrimerModifier,
        tokens: DesignTokens?
    ) -> ComputedProperties {
        return ComputedProperties(modifier: modifier, tokens: tokens)
    }
}

// MARK: - View Extension for Convenience

@available(iOS 15.0, *)
internal extension View {
    
    /// Applies extracted modifier properties to a view
    func primerExtractedModifiers(
        _ modifier: PrimerModifier,
        tokens: DesignTokens?
    ) -> some View {
        let props = PrimerModifierExtractor.computedProperties(modifier: modifier, tokens: tokens)
        
        return self
            .background(props.effectiveBackgroundColor)
            .cornerRadius(props.effectiveCornerRadius)
            .opacity(props.effectiveOpacity)
            .font(props.effectiveFont)
            .foregroundColor(props.effectiveForegroundColor)
    }
}