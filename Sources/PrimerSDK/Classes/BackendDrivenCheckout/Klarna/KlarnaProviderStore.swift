//
//  KlarnaProviderStore.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

final class KlarnaProviderStore {
    static let shared = KlarnaProviderStore()
    private var providers: [String: PrimerKlarnaProviding] = [:]
    
    private init() {}
    
    func set(_ provider: PrimerKlarnaProviding, for category: String) { providers[category] = provider }
    func provider(for category: String) -> PrimerKlarnaProviding? { providers[category] }
}
