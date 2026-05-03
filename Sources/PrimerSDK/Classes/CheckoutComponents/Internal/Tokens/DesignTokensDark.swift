//
//  DesignTokensDark.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable all
import SwiftUI

// This class is generated automatically by Style Dictionary.
// It represents the design tokens for the Dark theme.
final class DesignTokensDark: Decodable {
  public var primerColorGray100: Color? = Color(red: 0.161, green: 0.161, blue: 0.161, opacity: 1)
  public var primerColorGray200: Color? = Color(red: 0.259, green: 0.259, blue: 0.259, opacity: 1)
  public var primerColorGray300: Color? = Color(red: 0.341, green: 0.341, blue: 0.341, opacity: 1)
  public var primerColorGray400: Color? = Color(red: 0.522, green: 0.522, blue: 0.522, opacity: 1)
  public var primerColorGray500: Color? = Color(red: 0.463, green: 0.459, blue: 0.467, opacity: 1)
  public var primerColorGray600: Color? = Color(red: 0.780, green: 0.780, blue: 0.780, opacity: 1)
  public var primerColorGray700: Color? = Color(red: 0.858, green: 0.858, blue: 0.858, opacity: 1)
  public var primerColorGray900: Color? = Color(red: 0.937, green: 0.937, blue: 0.937, opacity: 1)
  public var primerColorGray000: Color? = Color(red: 0.090, green: 0.086, blue: 0.098, opacity: 1)
  public var primerColorGreen500: Color? = Color(red: 0.153, green: 0.694, blue: 0.490, opacity: 1)
  public var primerColorBrand: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
  public var primerColorRed100: Color? = Color(red: 0.196, green: 0.110, blue: 0.125, opacity: 1)
  public var primerColorRed500: Color? = Color(red: 0.894, green: 0.427, blue: 0.439, opacity: 1)
  public var primerColorRed900: Color? = Color(red: 0.965, green: 0.749, blue: 0.749, opacity: 1)
  public var primerColorBlue500: Color? = Color(red: 0.247, green: 0.576, blue: 0.894, opacity: 1)
  public var primerColorBlue900: Color? = Color(red: 0.290, green: 0.682, blue: 1.000, opacity: 1)

  enum CodingKeys: String, CodingKey {
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
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

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
