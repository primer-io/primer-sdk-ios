//
//  InputEnabledKey.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Whether the fields below accept input. Set once by the form, read by every field container, so a
/// screen does not have to thread a flag through a dozen views to lock what it already knows is busy.
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
