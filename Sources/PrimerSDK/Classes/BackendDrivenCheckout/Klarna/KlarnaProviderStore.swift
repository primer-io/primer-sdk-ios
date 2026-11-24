//
//  KlarnaProviderStore.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK

final class KlarnaProviderStore {
    static let shared = KlarnaProviderStore()
    private var providers: [String: PrimerKlarnaProviding] = [:]
    private var latestKey: String?

    private init() {
        // Use the shared instance
    }

    func set(_ provider: PrimerKlarnaProviding, for keys: [String]) {
        keys.forEach { providers[$0] = provider }
        latestKey = keys.first
    }

    func provider(for key: String?) -> PrimerKlarnaProviding? {
        (key ?? latestKey).flatMap { providers[$0] }
    }
}
#endif
