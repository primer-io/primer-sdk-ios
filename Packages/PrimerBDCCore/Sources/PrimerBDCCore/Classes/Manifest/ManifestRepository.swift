//
//  ManifestRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public protocol SignedManifestProvider {
    func fetchSignedManifest() async throws -> SignedManifest
}

public final class ManifestRepository {
    
    private let provider: SignedManifestProvider
    
    public init(provider: SignedManifestProvider) {
        self.provider = provider
    }
    
    public func fetchManifest() async throws -> Manifest {
        let signedManifest = try await provider.fetchSignedManifest()
        guard ManifestValidator.isValid(signedManifest) else { throw Error.invalidSignature }
        return try JSONDecoder().decode(Manifest.self, from: signedManifest.manifest)
    }
}

private extension ManifestRepository {
    enum Error: Swift.Error {
        case invalidSignature
        
        public var errorDescription: String? {
            switch self {
            case .invalidSignature: "Manifest signature verification failed."
            }
        }
    }
}
