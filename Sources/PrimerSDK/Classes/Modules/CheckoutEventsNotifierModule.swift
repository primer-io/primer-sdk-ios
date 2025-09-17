//
//  CheckoutEventsNotifierModule.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: MISSING_TESTS
final class CheckoutEventsNotifierModule {

    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: (() -> Void)?

    func fireDidStartTokenizationEvent() async throws {
        if let didStartTokenization {
            didStartTokenization()
        }
    }

    func fireDidFinishTokenizationEvent() async throws {
        if let didFinishTokenization {
            didFinishTokenization()
        }
    }
}
