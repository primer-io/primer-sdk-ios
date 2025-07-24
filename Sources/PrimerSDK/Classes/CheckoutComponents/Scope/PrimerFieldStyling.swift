//
//  PrimerFieldStyling.swift
//  PrimerSDK
//
//  Created by Claude on 26.6.25.
//

import SwiftUI

/// Styling configuration for Primer input fields, enabling deep customization of field appearance
/// including fonts, colors, borders, and layout properties.
@available(iOS 15.0, *)
public struct PrimerFieldStyling {

    // MARK: - Typography

    /// Custom font for the input text
    public let font: Font?

    /// Custom font for the field label
    public let labelFont: Font?

    // MARK: - Colors

    /// Text color for the input text
    public let textColor: Color?

    /// Text color for the field label
    public let labelColor: Color?

    /// Background color for the input field
    public let backgroundColor: Color?

    /// Border color for the input field
    public let borderColor: Color?

    /// Border color when the field is focused
    public let focusedBorderColor: Color?

    /// Border color when the field has an error
    public let errorBorderColor: Color?

    /// Placeholder text color
    public let placeholderColor: Color?

    // MARK: - Layout

    /// Corner radius for the input field
    public let cornerRadius: CGFloat?

    /// Border width for the input field
    public let borderWidth: CGFloat?

    /// Padding inside the input field
    public let padding: EdgeInsets?

    /// Height of the input field
    public let fieldHeight: CGFloat?

    // MARK: - Initialization

    public init(
        font: Font? = nil,
        labelFont: Font? = nil,
        textColor: Color? = nil,
        labelColor: Color? = nil,
        backgroundColor: Color? = nil,
        borderColor: Color? = nil,
        focusedBorderColor: Color? = nil,
        errorBorderColor: Color? = nil,
        placeholderColor: Color? = nil,
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        padding: EdgeInsets? = nil,
        fieldHeight: CGFloat? = nil
    ) {
        self.font = font
        self.labelFont = labelFont
        self.textColor = textColor
        self.labelColor = labelColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.focusedBorderColor = focusedBorderColor
        self.errorBorderColor = errorBorderColor
        self.placeholderColor = placeholderColor
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.padding = padding
        self.fieldHeight = fieldHeight
    }
}

// MARK: - Convenience Initializers

@available(iOS 15.0, *)
extension PrimerFieldStyling {

    /// Creates a styling configuration with common color overrides
    public static func colors(
        text: Color? = nil,
        label: Color? = nil,
        background: Color? = nil,
        border: Color? = nil,
        placeholder: Color? = nil
    ) -> PrimerFieldStyling {
        return PrimerFieldStyling(
            textColor: text,
            labelColor: label,
            backgroundColor: background,
            borderColor: border,
            placeholderColor: placeholder
        )
    }

    /// Creates a styling configuration with typography overrides
    public static func typography(
        font: Font? = nil,
        labelFont: Font? = nil
    ) -> PrimerFieldStyling {
        return PrimerFieldStyling(
            font: font,
            labelFont: labelFont
        )
    }

    /// Creates a styling configuration with layout overrides
    public static func layout(
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        padding: EdgeInsets? = nil,
        height: CGFloat? = nil
    ) -> PrimerFieldStyling {
        return PrimerFieldStyling(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            padding: padding,
            fieldHeight: height
        )
    }
}

// MARK: - Merge Support

@available(iOS 15.0, *)
extension PrimerFieldStyling {

    /// Merges this styling with another, with the other styling taking precedence for non-nil values
    public func merged(with other: PrimerFieldStyling?) -> PrimerFieldStyling {
        guard let other = other else { return self }

        return PrimerFieldStyling(
            font: other.font ?? self.font,
            labelFont: other.labelFont ?? self.labelFont,
            textColor: other.textColor ?? self.textColor,
            labelColor: other.labelColor ?? self.labelColor,
            backgroundColor: other.backgroundColor ?? self.backgroundColor,
            borderColor: other.borderColor ?? self.borderColor,
            focusedBorderColor: other.focusedBorderColor ?? self.focusedBorderColor,
            errorBorderColor: other.errorBorderColor ?? self.errorBorderColor,
            placeholderColor: other.placeholderColor ?? self.placeholderColor,
            cornerRadius: other.cornerRadius ?? self.cornerRadius,
            borderWidth: other.borderWidth ?? self.borderWidth,
            padding: other.padding ?? self.padding,
            fieldHeight: other.fieldHeight ?? self.fieldHeight
        )
    }
}
