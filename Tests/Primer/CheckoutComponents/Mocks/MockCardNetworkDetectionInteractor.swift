//
//  MockCardNetworkDetectionInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class MockCardNetworkDetectionInteractor: CardNetworkDetectionInteractor {

    private(set) var detectNetworksCallCount = 0
    private(set) var selectNetworkCallCount = 0
    private(set) var lastSelectedNetwork: CardNetwork?

    private let networkStreamPair = AsyncStream<[CardNetwork]>.makeStream()
    private let binStreamPair = AsyncStream<PrimerBinData>.makeStream()

    var networkDetectionStream: AsyncStream<[CardNetwork]> { networkStreamPair.stream }
    var binDataStream: AsyncStream<PrimerBinData> { binStreamPair.stream }

    /// Drives the network-detection stream so tests can simulate co-badge BIN emissions on demand.
    func emitNetworks(_ networks: [CardNetwork]) {
        networkStreamPair.continuation.yield(networks)
    }

    func emitBinData(_ binData: PrimerBinData) {
        binStreamPair.continuation.yield(binData)
    }

    func detectNetworks(for cardNumber: String) async {
        detectNetworksCallCount += 1
    }

    func selectNetwork(_ network: CardNetwork) async {
        selectNetworkCallCount += 1
        lastSelectedNetwork = network
    }

    func reset() {
        detectNetworksCallCount = 0
        selectNetworkCallCount = 0
        lastSelectedNetwork = nil
    }
}
