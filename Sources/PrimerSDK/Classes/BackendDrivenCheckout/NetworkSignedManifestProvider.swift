//
//  NetworkSignedManifestProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerBDCCore
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

struct NetworkSignedManifestProvider: SignedManifestProvider {
    private let environment: PrimerEnvironment

    init(token: DecodedJWTToken?) {
        environment = token?.env.flatMap(PrimerEnvironment.init) ?? .dev
    }

    func fetchSignedManifest() async throws -> SignedManifest {
        let endpoint: BackendDrivenCheckoutEndpoint = .manifest(environment: environment)
        return try await defaultNetworkService.request(endpoint)
    }
}
