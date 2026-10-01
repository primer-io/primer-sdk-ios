//
//  RecordingRequiredActionObserver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Records what the shared core reports about the pages it opens, readable from a synchronous test.
final class RecordingRequiredActionObserver: RequiredActionObserver, @unchecked Sendable {

    enum Call: Equatable {
        case redirectOpened(URL, paymentId: String?)
        case redirectReturned(paymentId: String?)
        case threeDSChallengeShown(provider: String, protocolVersion: String?)
    }

    private let lock = NSLock()
    private var recorded: [Call] = []

    var calls: [Call] { lock.withLock { recorded } }

    func redirectOpened(_ url: URL, paymentId: String?) async {
        record(.redirectOpened(url, paymentId: paymentId))
    }

    func redirectReturned(paymentId: String?) async {
        record(.redirectReturned(paymentId: paymentId))
    }

    func threeDSChallengeShown(provider: String, protocolVersion: String?) async {
        record(.threeDSChallengeShown(provider: provider, protocolVersion: protocolVersion))
    }

    private func record(_ call: Call) {
        lock.withLock { recorded.append(call) }
    }
}
