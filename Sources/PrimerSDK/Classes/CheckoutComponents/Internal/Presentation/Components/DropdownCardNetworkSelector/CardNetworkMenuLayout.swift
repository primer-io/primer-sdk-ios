//
//  CardNetworkMenuLayout.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CoreGraphics

struct CardNetworkMenuLayout {
  let gap: CGFloat
  let edgeInset: CGFloat
  let isRightToLeft: Bool

  func frame(below field: CGRect, size: CGSize, in bounds: CGRect) -> CGRect {
    let preferredX = isRightToLeft ? field.minX : field.maxX - size.width
    let originX = min(max(preferredX, bounds.minX + edgeInset), bounds.maxX - edgeInset - size.width)
    return CGRect(origin: CGPoint(x: originX, y: field.maxY + gap), size: size)
  }
}
