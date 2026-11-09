//
//  RemoteLogContext.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Fields merged into every remote log until cleared, like the Web SDK's log context.
/// Read when the log call is made, not when it is sent, so a clear right after a log can't race it.
final class RemoteLogContext: @unchecked Sendable {
  static let shared = RemoteLogContext()

  private var fields: [String: Any] = [:]
  private let lock = NSLock()

  subscript(key: String) -> Any? {
    get { lock.withLock { fields[key] } }
    set { lock.withLock { fields[key] = newValue } }
  }

  /// The caller's fields win over the context.
  func merged(into userInfo: [String: Any]?) -> [String: Any]? {
    let context = lock.withLock { fields }
    guard !context.isEmpty else { return userInfo }
    return context.merging(userInfo ?? [:]) { _, caller in caller }
  }
}
