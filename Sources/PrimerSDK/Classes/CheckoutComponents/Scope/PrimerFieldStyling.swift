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
