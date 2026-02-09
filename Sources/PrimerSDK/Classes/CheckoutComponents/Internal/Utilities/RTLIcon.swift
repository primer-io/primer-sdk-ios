//
//  RTLIcon.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
enum RTLIcon {
  static var backChevron: String {
    RTLSupport.isRightToLeft ? "chevron.right" : "chevron.left"
  }

  static var forwardChevron: String {
    RTLSupport.isRightToLeft ? "chevron.left" : "chevron.right"
  }
}
