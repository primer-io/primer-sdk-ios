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

    // MARK: - InstrumentedContainer resolveSync Tests

    func test_instrumentedContainer_resolveSync_returnsInstance() async throws {
        // Given
        let container = InstrumentedContainer()

        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in TestImplementation() }

        // Resolve async first to populate singleton cache
        _ = try await container.resolve(TestProtocol.self)

        // When
        let result: TestProtocol = try container.resolveSync(TestProtocol.self)

        // Then
        XCTAssertNotNil(result)
    }

    func test_instrumentedContainer_resolve_failedResolution_recordsMetrics() async {
        // Given
        let container = InstrumentedContainer()

        // When
        do {
            _ = try await container.resolve(TestProtocol.self)
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // Then - metrics should still have recorded the attempt
        let metrics = await container.getPerformanceMetrics()
        XCTAssertNotNil(metrics)
        XCTAssertEqual(metrics?.totalResolutions, 1)
    }

    func test_instrumentedContainer_unregister_removesRegistration() async throws {
        // Given
        let container = InstrumentedContainer()
        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in TestImplementation() }

        // Verify it resolves
        _ = try await container.resolve(TestProtocol.self)

        // When
        _ = await container.unregister(TestProtocol.self, name: nil)

        // Then
        do {
            _ = try await container.resolve(TestProtocol.self)
            XCTFail("Expected error after unregister")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
    }

    func test_instrumentedContainer_reset_clearsRegistrations() async throws {
        // Given
        let container = InstrumentedContainer()
        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in TestImplementation() }

        // When
        await container.reset(ignoreDependencies: [Never.Type]())

        // Then
        do {
            _ = try await container.resolve(TestProtocol.self)
            XCTFail("Expected error after reset")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
    }

    func test_instrumentedContainer_getPerformanceMetrics_withNoMetrics_returnsNil() async {
        // Given
        let container = InstrumentedContainer(metrics: nil)

        // When
        let metrics = await container.getPerformanceMetrics()

        // Then
        XCTAssertNil(metrics)
    }

    // MARK: - ContainerDiagnostics Tests

    func test_diagnostics_description_containsAllFields() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 10,
            singletonInstances: 5,
            weakReferences: 3,
            activeWeakReferences: 2,
            registeredTypes: [TypeKey(String.self), TypeKey(Int.self)]
        )

        // When
        let description = diagnostics.description

        // Then
        XCTAssertTrue(description.contains("10"))
        XCTAssertTrue(description.contains("5"))
        XCTAssertTrue(description.contains("3"))
        XCTAssertTrue(description.contains("2"))
        XCTAssertTrue(description.contains("Memory Efficiency"))
    }

    func test_diagnostics_memoryEfficiency_zeroWeakReferences_shows100Percent() {
        // Given - 0 weak references, so formula is 0/max(0,1)*100 = 0%
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 5,
            weakReferences: 0,
            activeWeakReferences: 0,
            registeredTypes: []
        )

        // When
        let description = diagnostics.description

        // Then
        XCTAssertTrue(description.contains("0.0%"))
    }

    func test_diagnostics_memoryEfficiency_allActive_shows100Percent() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 2,
            activeWeakReferences: 2,
            registeredTypes: []
        )

        // When
        let description = diagnostics.description

        // Then
        XCTAssertTrue(description.contains("100.0%"))
    }

    // MARK: - ContainerPerformanceMetrics Description Tests

    func test_performanceMetrics_description_containsAllFields() {
        // Given
        let metrics = ContainerPerformanceMetrics(
            totalResolutions: 100,
            averageResolutionTime: 1.5,
            slowestResolutions: [(TypeKey(String.self), 5.0), (TypeKey(Int.self), 3.0)],
            cacheHitRate: 0.85,
            memoryUsageEstimate: 1024
        )

        // When
        let description = metrics.description

        // Then
        XCTAssertTrue(description.contains("100"))
        XCTAssertTrue(description.contains("1.500"))
        XCTAssertTrue(description.contains("85.0%"))
        XCTAssertTrue(description.contains("1024"))
    }

    // MARK: - ContainerHealthReport Tests

    func test_healthReport_storesStatusAndIssues() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 1,
            activeWeakReferences: 1,
            registeredTypes: []
        )

        // When
        let report = ContainerHealthReport(
            status: .hasIssues,
            issues: [.orphanedRegistrations(2)],
            recommendations: ["Clean up unused registrations"],
            diagnostics: diagnostics
        )

        // Then
        XCTAssertEqual(report.status, .hasIssues)
        XCTAssertEqual(report.issues.count, 1)
        XCTAssertEqual(report.recommendations.count, 1)
    }

    func test_healthReport_healthyStatus() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 0,
            activeWeakReferences: 0,
            registeredTypes: []
        )

        // When
        let report = ContainerHealthReport(
            status: .healthy,
            issues: [],
            recommendations: [],
            diagnostics: diagnostics
        )

        // Then
        XCTAssertEqual(report.status, .healthy)
        XCTAssertTrue(report.issues.isEmpty)
        XCTAssertTrue(report.recommendations.isEmpty)
    }

    func test_healthReport_criticalStatus_withMultipleIssues() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 0,
            singletonInstances: 0,
            weakReferences: 0,
            activeWeakReferences: 0,
            registeredTypes: []
        )

        // When
        let report = ContainerHealthReport(
            status: .critical,
            issues: [
                .memoryLeak("ServiceA"),
                .circularDependency("A -> B -> A"),
                .deepResolutionStack("ServiceX"),
            ],
            recommendations: ["Fix circular dependency", "Investigate memory leak"],
            diagnostics: diagnostics
        )

        // Then
        XCTAssertEqual(report.status, .critical)
        XCTAssertEqual(report.issues.count, 3)
        XCTAssertEqual(report.recommendations.count, 2)
    }

    // MARK: - printDetailedReport / printReport Tests

    func test_diagnostics_printDetailedReport_doesNotCrash() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 3,
            singletonInstances: 2,
            weakReferences: 1,
            activeWeakReferences: 1,
            registeredTypes: [TypeKey(String.self), TypeKey(Int.self)]
        )

        // When / Then — should not crash
        diagnostics.printDetailedReport()
    }

    func test_healthReport_printReport_doesNotCrash() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 1,
            activeWeakReferences: 0,
            registeredTypes: []
        )
        let report = ContainerHealthReport(
            status: .hasIssues,
            issues: [.memoryLeak("TestService"), .orphanedRegistrations(2)],
            recommendations: ["Fix leak", "Clean up registrations"],
            diagnostics: diagnostics
        )

        // When / Then — should not crash
        report.printReport()
    }

    func test_healthReport_printReport_healthy_noIssues_doesNotCrash() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 5,
            weakReferences: 0,
            activeWeakReferences: 0,
            registeredTypes: []
        )
        let report = ContainerHealthReport(
            status: .healthy,
            issues: [],
            recommendations: [],
            diagnostics: diagnostics
        )

        // When / Then — should not crash
        report.printReport()
    }

    func test_instrumentedContainer_printPerformanceReport_doesNotCrash() async throws {
        // Given
        let container = InstrumentedContainer()
        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in TestImplementation() }
        _ = try await container.resolve(TestProtocol.self)

        // When / Then — should not crash
        await container.printPerformanceReport()
    }

    func test_instrumentedContainer_printPerformanceReport_noMetrics_doesNotCrash() async {
        // Given
        let container = InstrumentedContainer(metrics: nil)

        // When / Then — should not crash (nil metrics)
        await container.printPerformanceReport()
    }

    // MARK: - DefaultContainerMetrics recordRegistration Tests

    func test_metrics_recordRegistration_tracksCount() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let key = TypeKey(String.self)

        // When
        await metrics.recordRegistration(for: key)
        await metrics.recordRegistration(for: key)
        let result = await metrics.getMetrics()

        // Then
        XCTAssertGreaterThan(result.memoryUsageEstimate, 0)
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
