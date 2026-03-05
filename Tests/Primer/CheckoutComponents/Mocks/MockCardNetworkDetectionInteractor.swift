//
//  MockCardNetworkDetectionInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockCardNetworkDetectionInteractor: CardNetworkDetectionInteractor {

    private(set) var detectNetworksCallCount = 0

    var networkDetectionStream: AsyncStream<[CardNetwork]> {
        AsyncStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    var binDataStream: AsyncStream<PrimerBinData> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func detectNetworks(for cardNumber: String) async {
        detectNetworksCallCount += 1
    }

    func selectNetwork(_ network: CardNetwork) async {}
}
