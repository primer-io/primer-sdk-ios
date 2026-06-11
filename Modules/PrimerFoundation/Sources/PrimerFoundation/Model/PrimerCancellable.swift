//
//  PrimerCancellable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal)
public protocol PrimerCancellable {
    /// Cancel the associated task
    func cancel()
}

@_spi(PrimerInternal)
extension URLSessionDataTask: PrimerCancellable {}
