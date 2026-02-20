//
//  ManifestRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

final class ManifestRepository {
    
    func fetchManifest() async throws -> Manifest {
        let signedManifest: SignedManifest = try await request(.manifest)
        guard ManifestValidator.isValid(signedManifest) else { throw ManifestRepositoryError.invalidManifest }
        return try JSONDecoder().decode(Manifest.self, from: signedManifest.manifest)
    }
    
    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint) async throws -> T {
        try await defaultNetworkService.request(endpoint)
    }
}

private enum ManifestRepositoryError: Error {
    case invalidManifest
}
