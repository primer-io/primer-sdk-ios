//
//  Resolve.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

public nonisolated(unsafe) var resolveColor: (String) -> Color = { unregistered("resolveColor", token: $0, fallback: .clear) }
public nonisolated(unsafe) var resolveSpacing: (String) -> CGFloat = { unregistered("resolveSpacing", token: $0, fallback: 0) }
public nonisolated(unsafe) var resolveFont: (String) -> Font = { unregistered("resolveFont", token: $0, fallback: .body) }

private func unregistered<T>(_ resolver: String, token: String, fallback: T) -> T {
    let message = "\(resolver) was never registered — cannot resolve token '\(token)'"
    log(message, type: .error)
    assertionFailure(message)
    return fallback
}
