//
//  Color+RGBA.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// Theme colour overrides are pinned to the loaded scheme, so tests compare them by value, not by `Color` identity.
func rgba(_ color: Color?, _ style: UIUserInterfaceStyle = .light) -> [Int] {
  guard let color else { return [] }
  var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
  UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    .getRed(&red, green: &green, blue: &blue, alpha: &alpha)
  return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
}
