//
//  PrimerCancellable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol PrimerCancellable {
    /// Cancel the associated task
    func cancel()
}

extension URLSessionDataTask: PrimerCancellable {}
