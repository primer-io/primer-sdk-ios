//
//  MockCardNetworkDetectionInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of CardNetworkDetectionInteractor for testing.
/// Provides configurable network detection results and call tracking.
@available(iOS 15.0, *)
final class MockCardNetworkDetectionInteractor: CardNetworkDetectionInteractor {

    // MARK: - Configurable Return Values

    var networksToReturn: [CardNetwork] = []

    // MARK: - Call Tracking

    private(set) var detectNetworksCallCount = 0
    private(set) var selectNetworkCallCount = 0
    private(set) var lastCardNumber: String?
    private(set) var lastSelectedNetwork: CardNetwork?

    // MARK: - AsyncStream Support

    private var continuation: AsyncStream<[CardNetwork]>.Continuation?

    var networkDetectionStream: AsyncStream<[CardNetwork]> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
            // Emit initial value
            if let networks = self?.networksToReturn {
                continuation.yield(networks)
            }
        }
    }

    // MARK: - Protocol Implementation

    func detectNetworks(for cardNumber: String) async {
        detectNetworksCallCount += 1
        lastCardNumber = cardNumber
    }

    func selectNetwork(_ network: CardNetwork) async {
        selectNetworkCallCount += 1
        lastSelectedNetwork = network
    }

    // MARK: - Test Helpers

    func reset() {
        detectNetworksCallCount = 0
        selectNetworkCallCount = 0
        lastCardNumber = nil
        lastSelectedNetwork = nil
        networksToReturn = []
        continuation = nil
    }

    /// Emits a new set of detected networks through the stream
    func emitNetworks(_ networks: [CardNetwork]) {
        networksToReturn = networks
        continuation?.yield(networks)
    }
}
