//
//  RequiredActionObserver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Hears about the pages and the 3DS the shared core runs during one payment. Drop-in and headless set none.
protocol RequiredActionObserver: AnyObject, Sendable {
    func redirectOpened(_ url: URL, paymentId: String?) async
    func redirectReturned(paymentId: String?) async
    func threeDSChallengeShown(provider: String, protocolVersion: String?) async
    /// Only `AUTH_SUCCESS`, `AUTH_FAILED` and `SKIPPED` are reported.
    func threeDSCompleted(authenticationOutcome: String, skippedReasonCode: String?) async
}

enum ProcessorThreeDS {
    /// The provider Web reports for a processor-hosted challenge.
    static let provider = "PROCESSOR"
}
