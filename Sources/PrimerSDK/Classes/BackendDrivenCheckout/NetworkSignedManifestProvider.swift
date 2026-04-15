//
//  NetworkSignedManifestProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerBDCCore
import PrimerFoundation

struct NetworkSignedManifestProvider: SignedManifestProvider {
    func fetchSignedManifest() async throws -> SignedManifest {
        try await defaultNetworkService.request(BackendDrivenCheckoutEndpoint.manifest)
    }
}
