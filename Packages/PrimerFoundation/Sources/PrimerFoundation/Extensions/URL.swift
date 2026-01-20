//
//  URL.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension URL {
    var hasWebBasedScheme: Bool {
        ["http", "https"].contains(scheme?.lowercased() ?? "")
    }
    
    var schemeAndHost: String {
        [scheme, host].compactMap(\.self).joined(separator: "://")
    }
}
