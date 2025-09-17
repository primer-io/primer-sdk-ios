//
//  TimerExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

internal extension Timer {
    
    static func delay(_ timeInterval: TimeInterval) async throws {
        if #available(iOS 16.0, *) {
            try await Task.sleep(for: .seconds(timeInterval))
        } else {
            try await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
        }
    }
}
