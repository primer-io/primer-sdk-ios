//
//  RTLIcon.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
enum RTLIcon {
  static var backChevron: String {
    RTLSupport.isRightToLeft ? "chevron.right" : "chevron.left"
  }

  static var forwardChevron: String {
    RTLSupport.isRightToLeft ? "chevron.left" : "chevron.right"
  }
}
