//
//  MockCardNetworkDetectionInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

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
    private var binDataContinuation: AsyncStream<PrimerBinData>.Continuation?
    var binDataToReturn: PrimerBinData?

    var networkDetectionStream: AsyncStream<[CardNetwork]> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
            // Emit initial value
            if let networks = self?.networksToReturn {
                continuation.yield(networks)
            }
        }
    }

    var binDataStream: AsyncStream<PrimerBinData> {
        AsyncStream { [weak self] continuation in
            self?.binDataContinuation = continuation
            if let binData = self?.binDataToReturn {
                continuation.yield(binData)
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
        binDataToReturn = nil
        continuation = nil
        binDataContinuation = nil
    }

    /// Emits a new set of detected networks through the stream
    func emitNetworks(_ networks: [CardNetwork]) {
        networksToReturn = networks
        continuation?.yield(networks)
    }

    /// Emits bin data through the stream
    func emitBinData(_ binData: PrimerBinData) {
        binDataToReturn = binData
        binDataContinuation?.yield(binData)
    }
}
