//
//  PrimerFieldStyling.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Styling configuration for Primer input fields, enabling deep customization of field appearance
/// including fonts, colors, borders, and layout properties.
@available(iOS 15.0, *)
public struct PrimerFieldStyling {

  // MARK: - Typography

  public let fontName: String?
  public let fontSize: CGFloat?
  public let fontWeight: CGFloat?
  public let labelFontName: String?
  public let labelFontSize: CGFloat?
  public let labelFontWeight: CGFloat?

  // MARK: - Colors

  public let textColor: Color?
  public let labelColor: Color?
  public let backgroundColor: Color?
  public let borderColor: Color?
  public let focusedBorderColor: Color?
  public let errorBorderColor: Color?
  public let placeholderColor: Color?

  // MARK: - Layout

  public let cornerRadius: CGFloat?
  public let borderWidth: CGFloat?
  public let padding: EdgeInsets?
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
