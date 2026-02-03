//
//  RTLSupport.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

@available(iOS 15.0, *)
enum RTLSupport {
  static var isRightToLeft: Bool {
    UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
  }

  static var layoutDirection: LayoutDirection {
    isRightToLeft ? .rightToLeft : .leftToRight
  }
}
