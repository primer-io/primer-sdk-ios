//
//  InputFieldAnchorKey.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
private struct InputFieldAnchorKey: EnvironmentKey {
  static var defaultValue: WeakBox<UIView>? { nil }
}

@available(iOS 15.0, *)
extension EnvironmentValues {
  var inputFieldAnchor: WeakBox<UIView>? {
    get { self[InputFieldAnchorKey.self] }
    set { self[InputFieldAnchorKey.self] = newValue }
  }
}
