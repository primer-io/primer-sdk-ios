//
//  BDCEngineProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public typealias BDCEngineBuilder = @MainActor (SignedManifestProvider) async throws -> any BDCEngineProtocol

/// Owns the engine for the lifetime of a session, so it outlives any single checkout flow.
@MainActor @_spi(PrimerInternal)
public final class BDCEngineProvider {

    public static let shared = BDCEngineProvider(build: makeEngine)

    private let build: BDCEngineBuilder
    private var task: Task<any BDCEngineProtocol, Error>?

    public init(build: @escaping BDCEngineBuilder) {
        self.build = build
    }

    public func warmUp(manifestProvider: SignedManifestProvider) {
        guard task == nil else { return }
        _ = makeTask(manifestProvider: manifestProvider)
    }

    public func engine(manifestProvider: SignedManifestProvider) async throws -> any BDCEngineProtocol {
        let task = task ?? makeTask(manifestProvider: manifestProvider)
        do {
            return try await task.value
        } catch {
            self.task = nil
            throw error
        }
    }

    public func reset() {
        task?.cancel()
        task = nil
    }

    private func makeTask(manifestProvider: SignedManifestProvider) -> Task<any BDCEngineProtocol, Error> {
        let task = Task { try await build(manifestProvider) }
        self.task = task
        return task
    }

    static func makeEngine(manifestProvider: SignedManifestProvider) async throws -> any BDCEngineProtocol {
        let manifest = try await ManifestRepository(provider: manifestProvider).fetchManifest()
        return try await PrimerBDCEngine(manifest: manifest)
    }
}
