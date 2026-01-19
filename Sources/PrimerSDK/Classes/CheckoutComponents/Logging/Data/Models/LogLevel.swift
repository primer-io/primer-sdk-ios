//
//  LogLevel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum DatadogLogStatus: String, Codable, Sendable {
    case error
    case warn
    case info
}
