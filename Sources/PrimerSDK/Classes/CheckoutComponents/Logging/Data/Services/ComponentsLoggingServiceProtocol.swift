//
//  ComponentsLoggingServiceProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
protocol ComponentsLoggingServiceProtocol: Actor {
  func logInfo(message: String, event: String, userInfo: [String: Any]?) async
}
