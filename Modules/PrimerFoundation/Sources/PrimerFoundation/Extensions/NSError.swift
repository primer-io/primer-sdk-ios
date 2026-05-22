//
//  NSError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal)
public extension NSError {
    static var emptyDescriptionError: NSError {
        NSError(domain: "", code: 0001)
    }
}
