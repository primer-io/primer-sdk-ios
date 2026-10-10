//
//  InputEnabledKey.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Set once by the screen that owns the fields, so a lock does not have to be threaded through every view.
@available(iOS 15.0, *)
private struct InputEnabledKey: EnvironmentKey {
  static let defaultValue = true
}

@available(iOS 15.0, *)
extension EnvironmentValues {
  var isInputEnabled: Bool {
    get { self[InputEnabledKey.self] }
    set { self[InputEnabledKey.self] = newValue }
  }
}
