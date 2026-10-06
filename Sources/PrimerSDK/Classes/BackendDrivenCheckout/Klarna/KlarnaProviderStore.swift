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
    private var latestCategory: String?

    private init() {}

    func set(_ provider: PrimerKlarnaProviding, for category: String) {
        providers[category] = provider
        latestCategory = category
    }

    func provider(for category: String?) -> PrimerKlarnaProviding? {
        (category ?? latestCategory).flatMap { providers[$0] }
    }
}
#endif
