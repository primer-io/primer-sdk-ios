//
//  MockCardNetworkDetectionInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of CardNetworkDetectionInteractor for testing.
/// Provides configurable network detection results and call tracking.
@available(iOS 15.0, *)
final class MockCardNetworkDetectionInteractor: CardNetworkDetectionInteractor {
    var detectNetworksCallCount = 0
    var selectNetworkCallCount = 0
    var lastCardNumber: String?
    var lastSelectedNetwork: CardNetwork?
    var networksToReturn: [CardNetwork] = []

    private let continuation: AsyncStream<[CardNetwork]>.Continuation

    var networkDetectionStream: AsyncStream<[CardNetwork]> {
        AsyncStream { [weak self] continuation in
            if let networks = self?.networksToReturn {
                continuation.yield(networks)
            }
        }
    }

    init() {
        var cont: AsyncStream<[CardNetwork]>.Continuation!
        _ = AsyncStream<[CardNetwork]> { continuation in
            cont = continuation
        }
        self.continuation = cont
    }

    func detectNetworks(for cardNumber: String) async {
        detectNetworksCallCount += 1
        lastCardNumber = cardNumber
    }

    func selectNetwork(_ network: CardNetwork) async {
        selectNetworkCallCount += 1
        lastSelectedNetwork = network
    }

    func reset() {
        detectNetworksCallCount = 0
        selectNetworkCallCount = 0
        lastCardNumber = nil
        lastSelectedNetwork = nil
        networksToReturn = []
    }

    func emitNetworks(_ networks: [CardNetwork]) {
        networksToReturn = networks
        continuation.yield(networks)
    }
}
