//
//  ContainerDiagnosticsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ContainerDiagnosticsTests: XCTestCase {

    // MARK: - DefaultContainerMetrics Tests

    func test_metrics_recordResolution_tracksSuccessfully() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)

        // When
        await metrics.recordResolution(for: typeKey, duration: TestData.DIContainer.Duration.oneMs)
        await metrics.recordResolution(for: typeKey, duration: TestData.DIContainer.Duration.twoMs)
        await metrics.recordResolution(for: typeKey, duration: TestData.DIContainer.Duration.threeMs)
        let result = await metrics.getMetrics()

        // Then
        XCTAssertEqual(result.totalResolutions, 3)
    }

    func test_metrics_recordCacheHit_increasesHitRate() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)

        // When
        await metrics.recordCacheHit(for: typeKey)
        await metrics.recordCacheHit(for: typeKey)
        await metrics.recordCacheMiss(for: typeKey)
        let result = await metrics.getMetrics()

        // Then - 2 hits, 1 miss = 66.6% hit rate
        XCTAssertGreaterThan(result.cacheHitRate, 0.6)
        XCTAssertLessThan(result.cacheHitRate, 0.7)
    }

    func test_metrics_recordCacheMiss_decreasesHitRate() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)

        // When
        await metrics.recordCacheHit(for: typeKey)
        await metrics.recordCacheMiss(for: typeKey)
        await metrics.recordCacheMiss(for: typeKey)
        await metrics.recordCacheMiss(for: typeKey)
        let result = await metrics.getMetrics()

        // Then - 1 hit, 3 misses = 25% hit rate
        XCTAssertLessThan(result.cacheHitRate, 0.3)
    }

    func test_metrics_withNoActivity_returnsZeroValues() async {
        // Given
        let metrics = DefaultContainerMetrics()

        // When
        let result = await metrics.getMetrics()

        // Then
        XCTAssertEqual(result.totalResolutions, 0)
        XCTAssertEqual(result.averageResolutionTime, 0)
        XCTAssertEqual(result.cacheHitRate, 0)
        XCTAssertTrue(result.slowestResolutions.isEmpty)
    }

    func test_metrics_averageResolutionTime_calculatesCorrectly() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)

        // When - record 3 resolutions with 1ms, 2ms, 3ms
        await metrics.recordResolution(for: typeKey, duration: TestData.DIContainer.Duration.oneMs)
        await metrics.recordResolution(for: typeKey, duration: TestData.DIContainer.Duration.twoMs)
        await metrics.recordResolution(for: typeKey, duration: TestData.DIContainer.Duration.threeMs)
        let result = await metrics.getMetrics()

        // Then - average should be 2ms
        XCTAssertEqual(result.averageResolutionTime, 2.0, accuracy: 0.1)
    }

    func test_metrics_slowestResolutions_sortedDescending() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey1 = TypeKey(String.self, name: "fast")
        let typeKey2 = TypeKey(Int.self, name: "slow")
        let typeKey3 = TypeKey(Double.self, name: "medium")

        // When
        await metrics.recordResolution(for: typeKey1, duration: TestData.DIContainer.Duration.oneMs)
        await metrics.recordResolution(for: typeKey2, duration: TestData.DIContainer.Duration.tenMs)
        await metrics.recordResolution(for: typeKey3, duration: TestData.DIContainer.Duration.fiveMs)
        let result = await metrics.getMetrics()

        // Then - slowest should be first
        XCTAssertEqual(result.slowestResolutions.count, 3)
        XCTAssertGreaterThan(result.slowestResolutions[0].1, result.slowestResolutions[1].1)
        XCTAssertGreaterThan(result.slowestResolutions[1].1, result.slowestResolutions[2].1)
    }

    func test_metrics_multipleTypes_trackedSeparately() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let stringKey = TypeKey(String.self, name: nil)
        let intKey = TypeKey(Int.self, name: nil)

        // When
        await metrics.recordResolution(for: stringKey, duration: TestData.DIContainer.Duration.oneMs)
        await metrics.recordResolution(for: intKey, duration: TestData.DIContainer.Duration.twoMs)
        await metrics.recordCacheHit(for: stringKey)
        await metrics.recordCacheMiss(for: intKey)

        let result = await metrics.getMetrics()

        // Then
        XCTAssertEqual(result.totalResolutions, 2)
        XCTAssertEqual(result.slowestResolutions.count, 2)
    }

    // MARK: - InstrumentedContainer Tests

    func test_instrumentedContainer_recordsResolutionMetrics() async throws {
        // Given
        let container = InstrumentedContainer()

        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in
                TestImplementation()
            }

        // When
        _ = try await container.resolve(TestProtocol.self)
        _ = try await container.resolve(TestProtocol.self)
        let metrics = await container.getPerformanceMetrics()

        // Then
        XCTAssertNotNil(metrics)
        XCTAssertEqual(metrics?.totalResolutions, 2)
    }

    func test_instrumentedContainer_resolveAll_returnsAllInstances() async throws {
        // Given
        let container = InstrumentedContainer()

        _ = try await container.register(TestProtocol.self)
            .named("first")
            .asSingleton()
            .with { _ in
                TestImplementation()
            }

        _ = try await container.register(TestProtocol.self)
            .named("second")
            .asSingleton()
            .with { _ in
                TestImplementation()
            }

        // When
        let instances: [TestProtocol] = await container.resolveAll(TestProtocol.self)

        // Then
        XCTAssertEqual(instances.count, 2)
    }
}

// MARK: - Test Types

@available(iOS 15.0, *)
private protocol TestProtocol {
    func doSomething()
}

@available(iOS 15.0, *)
private final class TestImplementation: TestProtocol {
    func doSomething() {}
}
