//
//  PrimerFieldStyling.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Styling configuration for Primer input fields, enabling deep customization of field appearance
/// including fonts, colors, borders, and layout properties.
///
/// All properties are optional — any `nil` value falls back to the SDK's design token defaults.
///
/// ```swift
/// let styling = PrimerFieldStyling(
///     fontName: "Helvetica Neue",
///     fontSize: 16,
///     textColor: .primary,
///     backgroundColor: .gray.opacity(0.05),
///     borderColor: .gray.opacity(0.3),
///     focusedBorderColor: .blue,
///     errorBorderColor: .red,
///     cornerRadius: 8,
///     borderWidth: 1,
///     padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
///     fieldHeight: 56
/// )
/// ```
@available(iOS 15.0, *)
public struct PrimerFieldStyling {

  // MARK: - Typography

  /// Custom font family name for field input text (e.g., `"Helvetica Neue"`).
  public let fontName: String?
  /// Font size in points for field input text.
  public let fontSize: CGFloat?
  /// Font weight for field input text, specified as a `CGFloat` (e.g., `UIFont.Weight.bold.rawValue`).
  public let fontWeight: CGFloat?
  /// Custom font family name for field labels.
  public let labelFontName: String?
  /// Font size in points for field labels.
  public let labelFontSize: CGFloat?
  /// Font weight for field labels, specified as a `CGFloat`.
  public let labelFontWeight: CGFloat?

  // MARK: - Colors

  /// Color for the field's input text.
  public let textColor: Color?
  /// Color for the field's label text.
  public let labelColor: Color?
  /// Background color of the field.
  public let backgroundColor: Color?
  /// Border color in the default (unfocused) state.
  public let borderColor: Color?
  /// Border color when the field is focused.
  public let focusedBorderColor: Color?
  /// Border color when the field has a validation error.
  public let errorBorderColor: Color?
  /// Color for placeholder text.
  public let placeholderColor: Color?

  // MARK: - Layout

  /// Corner radius of the field's border.
  public let cornerRadius: CGFloat?
  /// Width of the field's border stroke.
  public let borderWidth: CGFloat?
  /// Inner padding of the field content.
  public let padding: EdgeInsets?
  /// Fixed height for the field.
  public let fieldHeight: CGFloat?

  // MARK: - Initialization

  public init(
    fontName: String? = nil,
    fontSize: CGFloat? = nil,
    fontWeight: CGFloat? = nil,
    labelFontName: String? = nil,
    labelFontSize: CGFloat? = nil,
    labelFontWeight: CGFloat? = nil,
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
    self.fontName = fontName
    self.fontSize = fontSize
    self.fontWeight = fontWeight
    self.labelFontName = labelFontName
    self.labelFontSize = labelFontSize
    self.labelFontWeight = labelFontWeight
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

  // MARK: - Internal Helpers

  func resolvedFont(tokens: DesignTokens?) -> Font {
    if let fontName = fontName {
      let uiFont = PrimerFont.uiFont(family: fontName, weight: fontWeight, size: fontSize)
      return Font(uiFont)
    }
    return PrimerFont.bodyLarge(tokens: tokens)
  }

  func resolvedLabelFont(tokens: DesignTokens?) -> Font {
    if let fontName = labelFontName {
      let uiFont = PrimerFont.uiFont(family: fontName, weight: labelFontWeight, size: labelFontSize)
      return Font(uiFont)
    }
    return PrimerFont.bodySmall(tokens: tokens)
  }
}
