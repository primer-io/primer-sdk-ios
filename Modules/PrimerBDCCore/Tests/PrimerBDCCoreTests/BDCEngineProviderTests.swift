//
//  BDCEngineProviderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

@MainActor
final class BDCEngineProviderTests: XCTestCase {

    func testEngineIsBuiltOncePerSession() async throws {
        let builder = EngineBuilderSpy()
        let sut = BDCEngineProvider(build: builder.build)

        let first = try await sut.engine(manifestProvider: StubManifestProvider())
        let second = try await sut.engine(manifestProvider: StubManifestProvider())

        XCTAssertIdentical(first, second)
        XCTAssertEqual(builder.callCount, 1)
    }

    func testOverlappingCallsAwaitTheSameBuild() async throws {
        let builder = EngineBuilderSpy()
        builder.delay = 20_000_000
        let sut = BDCEngineProvider(build: builder.build)

        async let first = sut.engine(manifestProvider: StubManifestProvider())
        async let second = sut.engine(manifestProvider: StubManifestProvider())

        let firstEngine = try await first
        let secondEngine = try await second

        XCTAssertIdentical(firstEngine, secondEngine)
        XCTAssertEqual(builder.callCount, 1)
    }

    func testResetForcesRebuild() async throws {
        let builder = EngineBuilderSpy()
        let sut = BDCEngineProvider(build: builder.build)

        let first = try await sut.engine(manifestProvider: StubManifestProvider())
        sut.reset()
        let second = try await sut.engine(manifestProvider: StubManifestProvider())

        XCTAssertNotIdentical(first, second)
        XCTAssertEqual(builder.callCount, 2)
    }

    func testFailedBuildIsNotCached() async throws {
        let builder = EngineBuilderSpy()
        builder.errors = [Failure.buildFailed]
        let sut = BDCEngineProvider(build: builder.build)

        do {
            _ = try await sut.engine(manifestProvider: StubManifestProvider())
            XCTFail("Expected the first build to fail")
        } catch {
            XCTAssertTrue(error is Failure)
        }

        _ = try await sut.engine(manifestProvider: StubManifestProvider())
        XCTAssertEqual(builder.callCount, 2)
    }
}

private extension BDCEngineProviderTests {
    enum Failure: Error {
        case buildFailed
    }
}

@MainActor
private final class EngineBuilderSpy {
    var callCount = 0
    var delay: UInt64 = 0
    var errors: [Error] = []

    func build(_ manifestProvider: SignedManifestProvider) async throws -> any BDCEngineProtocol {
        callCount += 1
        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        if !errors.isEmpty { throw errors.removeFirst() }
        return MockBDCEngine()
    }
}

private struct StubManifestProvider: SignedManifestProvider {
    func fetchSignedManifest() async throws -> SignedManifest {
        throw BDCEngineProviderTests.Failure.buildFailed
    }
}
