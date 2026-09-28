//
//  NetworkSignedManifestProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerBDCCore
import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

struct NetworkSignedManifestProvider: SignedManifestProvider {
    let env: String

    func fetchSignedManifest() async throws -> SignedManifest {
        let (manifest, _): (SignedManifest, [String: String]?) = try await defaultNetworkService.request(
            BackendDrivenCheckoutEndpoint.manifest(env: env),
            retryConfig: .manifest
        )
        return manifest
    }
}

extension NetworkSignedManifestProvider {
    /// The client token's environment, known before the configuration is.
    static var current: NetworkSignedManifestProvider? {
        let env = PrimerAPIConfigurationModule.decodedJWTToken?.env ?? PrimerAPIConfiguration.current?.env?.rawValue
        return env.map(NetworkSignedManifestProvider.init)
    }
}

// Three attempts, 300 ms then 600 ms apart. A bad signature isn't a download failure, so it isn't retried.
private extension RetryConfig {
    static let manifest = RetryConfig(enabled: true, maxRetries: 2, initialBackoff: 0.3, retry500Errors: true, maxJitter: 0)
}
