//
//  DesignTokens.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable all
import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

// This class is generated automatically by Style Dictionary.
// It represents the design tokens for the Light theme.
final class DesignTokens: Decodable {
  var primerColorBackground: Color? = Color(
    red: 1.000, green: 1.000, blue: 1.000, opacity: 1)
  var primerColorTextPrimary: Color? = Color(
    red: 0.129, green: 0.129, blue: 0.129, opacity: 1)
  var primerColorTextPlaceholder: Color? = Color(
    red: 0.620, green: 0.620, blue: 0.620, opacity: 1)
  var primerColorTextDisabled: Color? = Color(
    red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
  var primerColorTextNegative: Color? = Color(
    red: 0.706, green: 0.196, blue: 0.294, opacity: 1)
  var primerColorTextLink: Color? = Color(red: 0.133, green: 0.439, blue: 0.957, opacity: 1)
  var primerColorTextSecondary: Color? = Color(
    red: 0.459, green: 0.459, blue: 0.459, opacity: 1)
  var primerColorBorderOutlinedDefault: Color? = Color(
    red: 0.878, green: 0.878, blue: 0.878, opacity: 1)
  var primerColorBorderOutlinedHover: Color? = Color(
    red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
  var primerColorBorderOutlinedActive: Color? = Color(
    red: 0.620, green: 0.620, blue: 0.620, opacity: 1)
  var primerColorBorderOutlinedFocus: Color? = Color(
    red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
  var primerColorBorderOutlinedDisabled: Color? = Color(
    red: 0.933, green: 0.933, blue: 0.933, opacity: 1)
  var primerColorBorderOutlinedLoading: Color? = Color(
    red: 0.933, green: 0.933, blue: 0.933, opacity: 1)
  var primerColorBorderOutlinedSelected: Color? = Color(
    red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
  var primerColorBorderOutlinedError: Color? = Color(
    red: 1.000, green: 0.447, blue: 0.475, opacity: 1)
  var primerColorBorderTransparentDefault: Color? = Color(
    red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
  var primerColorBorderTransparentHover: Color? = Color(
    red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
  var primerColorBorderTransparentActive: Color? = Color(
    red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
  var primerColorBorderTransparentFocus: Color? = Color(
    red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
  var primerColorBorderTransparentDisabled: Color? = Color(
    red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
  var primerColorBorderTransparentSelected: Color? = Color(
    red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
  var primerColorIconPrimary: Color? = Color(
    red: 0.129, green: 0.129, blue: 0.129, opacity: 1)
  var primerColorIconDisabled: Color? = Color(
    red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
  var primerColorIconNegative: Color? = Color(
    red: 1.000, green: 0.447, blue: 0.475, opacity: 1)
  var primerColorIconPositive: Color? = Color(
    red: 0.243, green: 0.714, blue: 0.561, opacity: 1)
  var primerColorFocus: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
  var primerColorLoader: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
  var primerColorGray100: Color? = Color(red: 0.961, green: 0.961, blue: 0.961, opacity: 1)
  var primerColorGray200: Color? = Color(red: 0.933, green: 0.933, blue: 0.933, opacity: 1)
  var primerColorGray300: Color? = Color(red: 0.878, green: 0.878, blue: 0.878, opacity: 1)
  var primerColorGray400: Color? = Color(red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
  var primerColorGray500: Color? = Color(red: 0.620, green: 0.620, blue: 0.620, opacity: 1)
  var primerColorGray600: Color? = Color(red: 0.459, green: 0.459, blue: 0.459, opacity: 1)
  var primerColorGray700: Color? = Color(red: 0.294, green: 0.294, blue: 0.294, opacity: 1)
  var primerColorGray900: Color? = Color(red: 0.129, green: 0.129, blue: 0.129, opacity: 1)
  var primerColorGray000: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 1)
  var primerColorGreen500: Color? = Color(red: 0.243, green: 0.714, blue: 0.561, opacity: 1)
  var primerColorBrand: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
  var primerColorRed100: Color? = Color(red: 1.000, green: 0.925, blue: 0.925, opacity: 1)
  var primerColorRed500: Color? = Color(red: 1.000, green: 0.447, blue: 0.475, opacity: 1)
  var primerColorRed900: Color? = Color(red: 0.706, green: 0.196, blue: 0.294, opacity: 1)
  var primerColorBlue500: Color? = Color(red: 0.224, green: 0.616, blue: 1.000, opacity: 1)
  var primerColorBlue900: Color? = Color(red: 0.133, green: 0.439, blue: 0.957, opacity: 1)
  var primerBorderWidthThin: CGFloat? = 1
  var primerBorderWidthMedium: CGFloat? = 2
  var primerBorderWidthThick: CGFloat? = 3
  var primerRadiusMedium: CGFloat? = 8
  var primerRadiusSmall: CGFloat? = 4
  var primerRadiusLarge: CGFloat? = 12
  var primerRadiusXsmall: CGFloat? = 2
  var primerRadiusBase: CGFloat? = 4
  var primerTypographyBrand: String? = "Inter"
  var primerTypographyTitleXlargeFont: String? = "Inter"
  var primerTypographyTitleXlargeLetterSpacing: CGFloat? = -0.6
  var primerTypographyTitleXlargeWeight: CGFloat? = 550
  var primerTypographyTitleXlargeSize: CGFloat? = 24
  var primerTypographyTitleXlargeLineHeight: CGFloat? = 32
  var primerTypographyTitleLargeFont: String? = "Inter"
  var primerTypographyTitleLargeLetterSpacing: CGFloat? = -0.2
  var primerTypographyTitleLargeWeight: CGFloat? = 550
  var primerTypographyTitleLargeSize: CGFloat? = 16
  var primerTypographyTitleLargeLineHeight: CGFloat? = 20
  var primerTypographyBodyLargeFont: String? = "Inter"
  var primerTypographyBodyLargeLetterSpacing: CGFloat? = -0.2
  var primerTypographyBodyLargeWeight: CGFloat? = 400
  var primerTypographyBodyLargeSize: CGFloat? = 16
  var primerTypographyBodyLargeLineHeight: CGFloat? = 20
  var primerTypographyBodyMediumFont: String? = "Inter"
  var primerTypographyBodyMediumLetterSpacing: CGFloat? = 0
  var primerTypographyBodyMediumWeight: CGFloat? = 400
  var primerTypographyBodyMediumSize: CGFloat? = 14
  var primerTypographyBodyMediumLineHeight: CGFloat? = 20
  var primerTypographyBodySmallFont: String? = "Inter"
  var primerTypographyBodySmallLetterSpacing: CGFloat? = 0
  var primerTypographyBodySmallWeight: CGFloat? = 400
  var primerTypographyBodySmallSize: CGFloat? = 12
  var primerTypographyBodySmallLineHeight: CGFloat? = 16
  var primerSpaceXxsmall: CGFloat? = 2
  var primerSpaceXsmall: CGFloat? = 4
  var primerSpaceSmall: CGFloat? = 8
  var primerSpaceMedium: CGFloat? = 12
  var primerSpaceLarge: CGFloat? = 16
  var primerSpaceXlarge: CGFloat? = 20
  var primerSpaceXxlarge: CGFloat? = 24
  var primerSpaceBase: CGFloat? = 4
  var primerSizeSmall: CGFloat? = 16
  var primerSizeMedium: CGFloat? = 20
  var primerSizeLarge: CGFloat? = 24
  var primerSizeXlarge: CGFloat? = 32
  var primerSizeXxlarge: CGFloat? = 44
  var primerSizeXxxlarge: CGFloat? = 56
  var primerSizeBase: CGFloat? = 4

  // Coding keys to map JSON keys to properties.
  enum CodingKeys: String, CodingKey {
    case primerColorBackground
    case primerColorTextPrimary
    case primerColorTextPlaceholder
    case primerColorTextDisabled
    case primerColorTextNegative
    case primerColorTextLink
    case primerColorTextSecondary
    case primerColorBorderOutlinedDefault
    case primerColorBorderOutlinedHover
    case primerColorBorderOutlinedActive
    case primerColorBorderOutlinedFocus
    case primerColorBorderOutlinedDisabled
    case primerColorBorderOutlinedLoading
    case primerColorBorderOutlinedSelected
    case primerColorBorderOutlinedError
    case primerColorBorderTransparentDefault
    case primerColorBorderTransparentHover
    case primerColorBorderTransparentActive
    case primerColorBorderTransparentFocus
    case primerColorBorderTransparentDisabled
    case primerColorBorderTransparentSelected
    case primerColorIconPrimary
    case primerColorIconDisabled
    case primerColorIconNegative
    case primerColorIconPositive
    case primerColorFocus
    case primerColorLoader
    case primerColorGray100
    case primerColorGray200
    case primerColorGray300
    case primerColorGray400
    case primerColorGray500
    case primerColorGray600
    case primerColorGray700
    case primerColorGray900
    case primerColorGray000
    case primerColorGreen500
    case primerColorBrand
    case primerColorRed100
    case primerColorRed500
    case primerColorRed900
    case primerColorBlue500
    case primerColorBlue900
    case primerBorderWidthThin
    case primerBorderWidthMedium
    case primerBorderWidthThick
    case primerRadiusMedium
    case primerRadiusSmall
    case primerRadiusLarge
    case primerRadiusXsmall
    case primerRadiusBase
    case primerTypographyBrand
    case primerTypographyTitleXlargeFont
    case primerTypographyTitleXlargeLetterSpacing
    case primerTypographyTitleXlargeWeight
    case primerTypographyTitleXlargeSize
    case primerTypographyTitleXlargeLineHeight
    case primerTypographyTitleLargeFont
    case primerTypographyTitleLargeLetterSpacing
    case primerTypographyTitleLargeWeight
    case primerTypographyTitleLargeSize
    case primerTypographyTitleLargeLineHeight
    case primerTypographyBodyLargeFont
    case primerTypographyBodyLargeLetterSpacing
    case primerTypographyBodyLargeWeight
    case primerTypographyBodyLargeSize
    case primerTypographyBodyLargeLineHeight
    case primerTypographyBodyMediumFont
    case primerTypographyBodyMediumLetterSpacing
    case primerTypographyBodyMediumWeight
    case primerTypographyBodyMediumSize
    case primerTypographyBodyMediumLineHeight
    case primerTypographyBodySmallFont
    case primerTypographyBodySmallLetterSpacing
    case primerTypographyBodySmallWeight
    case primerTypographyBodySmallSize
    case primerTypographyBodySmallLineHeight
    case primerSpaceXxsmall
    case primerSpaceXsmall
    case primerSpaceSmall
    case primerSpaceMedium
    case primerSpaceLarge
    case primerSpaceXlarge
    case primerSpaceXxlarge
    case primerSpaceBase
    case primerSizeSmall
    case primerSizeMedium
    case primerSizeLarge
    case primerSizeXlarge
    case primerSizeXxlarge
    case primerSizeXxxlarge
    case primerSizeBase
  }

  // Default initializer preserves default values
  init() {}

  // Custom initializer to decode from JSON.
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    primerColorBackground = try container.decodeColorIfPresent(forKey: .primerColorBackground) ?? primerColorBackground
    primerColorTextPrimary = try container.decodeColorIfPresent(forKey: .primerColorTextPrimary) ?? primerColorTextPrimary
    primerColorTextPlaceholder = try container.decodeColorIfPresent(forKey: .primerColorTextPlaceholder) ?? primerColorTextPlaceholder
    primerColorTextDisabled = try container.decodeColorIfPresent(forKey: .primerColorTextDisabled) ?? primerColorTextDisabled
    primerColorTextNegative = try container.decodeColorIfPresent(forKey: .primerColorTextNegative) ?? primerColorTextNegative
    primerColorTextLink = try container.decodeColorIfPresent(forKey: .primerColorTextLink) ?? primerColorTextLink
    primerColorTextSecondary = try container.decodeColorIfPresent(forKey: .primerColorTextSecondary) ?? primerColorTextSecondary
    primerColorBorderOutlinedDefault = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedDefault) ?? primerColorBorderOutlinedDefault
    primerColorBorderOutlinedHover = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedHover) ?? primerColorBorderOutlinedHover
    primerColorBorderOutlinedActive = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedActive) ?? primerColorBorderOutlinedActive
    primerColorBorderOutlinedFocus = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedFocus) ?? primerColorBorderOutlinedFocus
    primerColorBorderOutlinedDisabled = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedDisabled) ?? primerColorBorderOutlinedDisabled
    primerColorBorderOutlinedLoading = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedLoading) ?? primerColorBorderOutlinedLoading
    primerColorBorderOutlinedSelected = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedSelected) ?? primerColorBorderOutlinedSelected
    primerColorBorderOutlinedError = try container.decodeColorIfPresent(forKey: .primerColorBorderOutlinedError) ?? primerColorBorderOutlinedError
    primerColorBorderTransparentDefault = try container.decodeColorIfPresent(forKey: .primerColorBorderTransparentDefault) ?? primerColorBorderTransparentDefault
    primerColorBorderTransparentHover = try container.decodeColorIfPresent(forKey: .primerColorBorderTransparentHover) ?? primerColorBorderTransparentHover
    primerColorBorderTransparentActive = try container.decodeColorIfPresent(forKey: .primerColorBorderTransparentActive) ?? primerColorBorderTransparentActive
    primerColorBorderTransparentFocus = try container.decodeColorIfPresent(forKey: .primerColorBorderTransparentFocus) ?? primerColorBorderTransparentFocus
    primerColorBorderTransparentDisabled = try container.decodeColorIfPresent(forKey: .primerColorBorderTransparentDisabled) ?? primerColorBorderTransparentDisabled
    primerColorBorderTransparentSelected = try container.decodeColorIfPresent(forKey: .primerColorBorderTransparentSelected) ?? primerColorBorderTransparentSelected
    primerColorIconPrimary = try container.decodeColorIfPresent(forKey: .primerColorIconPrimary) ?? primerColorIconPrimary
    primerColorIconDisabled = try container.decodeColorIfPresent(forKey: .primerColorIconDisabled) ?? primerColorIconDisabled
    primerColorIconNegative = try container.decodeColorIfPresent(forKey: .primerColorIconNegative) ?? primerColorIconNegative
    primerColorIconPositive = try container.decodeColorIfPresent(forKey: .primerColorIconPositive) ?? primerColorIconPositive
    primerColorFocus = try container.decodeColorIfPresent(forKey: .primerColorFocus) ?? primerColorFocus
    primerColorLoader = try container.decodeColorIfPresent(forKey: .primerColorLoader) ?? primerColorLoader
    primerColorGray100 = try container.decodeColorIfPresent(forKey: .primerColorGray100) ?? primerColorGray100
    primerColorGray200 = try container.decodeColorIfPresent(forKey: .primerColorGray200) ?? primerColorGray200
    primerColorGray300 = try container.decodeColorIfPresent(forKey: .primerColorGray300) ?? primerColorGray300
    primerColorGray400 = try container.decodeColorIfPresent(forKey: .primerColorGray400) ?? primerColorGray400
    primerColorGray500 = try container.decodeColorIfPresent(forKey: .primerColorGray500) ?? primerColorGray500
    primerColorGray600 = try container.decodeColorIfPresent(forKey: .primerColorGray600) ?? primerColorGray600
    primerColorGray700 = try container.decodeColorIfPresent(forKey: .primerColorGray700) ?? primerColorGray700
    primerColorGray900 = try container.decodeColorIfPresent(forKey: .primerColorGray900) ?? primerColorGray900
    primerColorGray000 = try container.decodeColorIfPresent(forKey: .primerColorGray000) ?? primerColorGray000
    primerColorGreen500 = try container.decodeColorIfPresent(forKey: .primerColorGreen500) ?? primerColorGreen500
    primerColorBrand = try container.decodeColorIfPresent(forKey: .primerColorBrand) ?? primerColorBrand
    primerColorRed100 = try container.decodeColorIfPresent(forKey: .primerColorRed100) ?? primerColorRed100
    primerColorRed500 = try container.decodeColorIfPresent(forKey: .primerColorRed500) ?? primerColorRed500
    primerColorRed900 = try container.decodeColorIfPresent(forKey: .primerColorRed900) ?? primerColorRed900
    primerColorBlue500 = try container.decodeColorIfPresent(forKey: .primerColorBlue500) ?? primerColorBlue500
    primerColorBlue900 = try container.decodeColorIfPresent(forKey: .primerColorBlue900) ?? primerColorBlue900
    primerBorderWidthThin = try container.decodeIfPresent(CGFloat.self, forKey: .primerBorderWidthThin) ?? primerBorderWidthThin
    primerBorderWidthMedium = try container.decodeIfPresent(CGFloat.self, forKey: .primerBorderWidthMedium) ?? primerBorderWidthMedium
    primerBorderWidthThick = try container.decodeIfPresent(CGFloat.self, forKey: .primerBorderWidthThick) ?? primerBorderWidthThick
    primerRadiusMedium = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerRadiusMedium) ?? primerRadiusMedium
    primerRadiusSmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusSmall) ?? primerRadiusSmall
    primerRadiusLarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusLarge) ?? primerRadiusLarge
    primerRadiusXsmall = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerRadiusXsmall) ?? primerRadiusXsmall
    primerRadiusBase = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusBase) ?? primerRadiusBase
    primerTypographyBrand = try container.decodeIfPresent(
      String.self, forKey: .primerTypographyBrand) ?? primerTypographyBrand
    primerTypographyTitleXlargeFont = try container.decodeIfPresent(
      String.self, forKey: .primerTypographyTitleXlargeFont) ?? primerTypographyTitleXlargeFont
    primerTypographyTitleXlargeLetterSpacing = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleXlargeLetterSpacing) ?? primerTypographyTitleXlargeLetterSpacing
    primerTypographyTitleXlargeWeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleXlargeWeight) ?? primerTypographyTitleXlargeWeight
    primerTypographyTitleXlargeSize = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleXlargeSize) ?? primerTypographyTitleXlargeSize
    primerTypographyTitleXlargeLineHeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleXlargeLineHeight) ?? primerTypographyTitleXlargeLineHeight
    primerTypographyTitleLargeFont = try container.decodeIfPresent(
      String.self, forKey: .primerTypographyTitleLargeFont) ?? primerTypographyTitleLargeFont
    primerTypographyTitleLargeLetterSpacing = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleLargeLetterSpacing) ?? primerTypographyTitleLargeLetterSpacing
    primerTypographyTitleLargeWeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleLargeWeight) ?? primerTypographyTitleLargeWeight
    primerTypographyTitleLargeSize = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleLargeSize) ?? primerTypographyTitleLargeSize
    primerTypographyTitleLargeLineHeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyTitleLargeLineHeight) ?? primerTypographyTitleLargeLineHeight
    primerTypographyBodyLargeFont = try container.decodeIfPresent(
      String.self, forKey: .primerTypographyBodyLargeFont) ?? primerTypographyBodyLargeFont
    primerTypographyBodyLargeLetterSpacing = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyLargeLetterSpacing) ?? primerTypographyBodyLargeLetterSpacing
    primerTypographyBodyLargeWeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyLargeWeight) ?? primerTypographyBodyLargeWeight
    primerTypographyBodyLargeSize = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyLargeSize) ?? primerTypographyBodyLargeSize
    primerTypographyBodyLargeLineHeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyLargeLineHeight) ?? primerTypographyBodyLargeLineHeight
    primerTypographyBodyMediumFont = try container.decodeIfPresent(
      String.self, forKey: .primerTypographyBodyMediumFont) ?? primerTypographyBodyMediumFont
    primerTypographyBodyMediumLetterSpacing = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyMediumLetterSpacing) ?? primerTypographyBodyMediumLetterSpacing
    primerTypographyBodyMediumWeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyMediumWeight) ?? primerTypographyBodyMediumWeight
    primerTypographyBodyMediumSize = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyMediumSize) ?? primerTypographyBodyMediumSize
    primerTypographyBodyMediumLineHeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodyMediumLineHeight) ?? primerTypographyBodyMediumLineHeight
    primerTypographyBodySmallFont = try container.decodeIfPresent(
      String.self, forKey: .primerTypographyBodySmallFont) ?? primerTypographyBodySmallFont
    primerTypographyBodySmallLetterSpacing = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodySmallLetterSpacing) ?? primerTypographyBodySmallLetterSpacing
    primerTypographyBodySmallWeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodySmallWeight) ?? primerTypographyBodySmallWeight
    primerTypographyBodySmallSize = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodySmallSize) ?? primerTypographyBodySmallSize
    primerTypographyBodySmallLineHeight = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerTypographyBodySmallLineHeight) ?? primerTypographyBodySmallLineHeight
    primerSpaceXxsmall = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerSpaceXxsmall) ?? primerSpaceXxsmall
    primerSpaceXsmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceXsmall) ?? primerSpaceXsmall
    primerSpaceSmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceSmall) ?? primerSpaceSmall
    primerSpaceMedium = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceMedium) ?? primerSpaceMedium
    primerSpaceLarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceLarge) ?? primerSpaceLarge
    primerSpaceXlarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceXlarge) ?? primerSpaceXlarge
    primerSpaceXxlarge = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerSpaceXxlarge) ?? primerSpaceXxlarge
    primerSpaceBase = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceBase) ?? primerSpaceBase
    primerSizeSmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeSmall) ?? primerSizeSmall
    primerSizeMedium = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeMedium) ?? primerSizeMedium
    primerSizeLarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeLarge) ?? primerSizeLarge
    primerSizeXlarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeXlarge) ?? primerSizeXlarge
    primerSizeXxlarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeXxlarge) ?? primerSizeXxlarge
    primerSizeXxxlarge = try container.decodeIfPresent(
      CGFloat.self, forKey: .primerSizeXxxlarge) ?? primerSizeXxxlarge
    primerSizeBase = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeBase) ?? primerSizeBase
  }
}

private extension KeyedDecodingContainer {
  func decodeColorIfPresent(forKey key: Key) throws -> Color? {
    guard let components = try decodeIfPresent([CGFloat].self, forKey: key),
      components.count >= 4
    else { return nil }
    return Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
  }
}
// swiftlint:enable all
