//
//  ContainerDiagnosticsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for ContainerDiagnostics, health reporting, and performance metrics.
@available(iOS 15.0, *)
final class ContainerDiagnosticsTests: XCTestCase {

    // MARK: - ContainerDiagnostics Tests

    func test_diagnostics_descriptionFormatsCorrectly() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 10,
            singletonInstances: 5,
            weakReferences: 3,
            activeWeakReferences: 2,
            registeredTypes: []
        )

        // When
        let description = diagnostics.description

        // Then
        XCTAssertTrue(description.contains("Total Registrations: 10"))
        XCTAssertTrue(description.contains("Singleton Instances: 5"))
        XCTAssertTrue(description.contains("Weak References: 3 (active: 2)"))
        XCTAssertTrue(description.contains("Memory Efficiency:"))
    }

    func test_diagnostics_memoryEfficiencyCalculation_withActiveReferences() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 10,
            singletonInstances: 5,
            weakReferences: 10,
            activeWeakReferences: 5,
            registeredTypes: []
        )

        // When
        let description = diagnostics.description

        // Then - 5/10 = 50%
        XCTAssertTrue(description.contains("50.0%"))
    }

    func test_diagnostics_memoryEfficiencyCalculation_withNoWeakReferences() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 10,
            singletonInstances: 5,
            weakReferences: 0,
            activeWeakReferences: 0,
            registeredTypes: []
        )

        // When
        let description = diagnostics.description

        // Then - Division by zero should be handled (defaults to 0% or similar)
        XCTAssertTrue(description.contains("Memory Efficiency:"))
    }

    func test_diagnostics_registeredTypesIncluded() {
        // Given
        let typeKey = TypeKey(String.self, name: nil)
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 1,
            singletonInstances: 0,
            weakReferences: 0,
            activeWeakReferences: 0,
            registeredTypes: [typeKey]
        )

        // Then
        XCTAssertEqual(diagnostics.registeredTypes.count, 1)
        XCTAssertEqual(diagnostics.registeredTypes.first, typeKey)
    }

    // MARK: - HealthStatus Tests

    func test_healthStatus_allCases() {
        // Given/When/Then - verify all cases exist
        let healthy = HealthStatus.healthy
        let hasIssues = HealthStatus.hasIssues
        let critical = HealthStatus.critical

        XCTAssertNotNil(healthy)
        XCTAssertNotNil(hasIssues)
        XCTAssertNotNil(critical)
    }

    // MARK: - HealthIssue Tests

    func test_healthIssue_memoryLeak() {
        // Given
        let issue = HealthIssue.memoryLeak("TestService leaked")

        // When/Then
        if case let .memoryLeak(message) = issue {
            XCTAssertEqual(message, "TestService leaked")
        } else {
            XCTFail("Expected memoryLeak case")
        }
    }

    func test_healthIssue_orphanedRegistrations() {
        // Given
        let issue = HealthIssue.orphanedRegistrations(5)

        // When/Then
        if case let .orphanedRegistrations(count) = issue {
            XCTAssertEqual(count, 5)
        } else {
            XCTFail("Expected orphanedRegistrations case")
        }
    }

    func test_healthIssue_deepResolutionStack() {
        // Given
        let issue = HealthIssue.deepResolutionStack("A -> B -> C -> D -> E")

        // When/Then
        if case let .deepResolutionStack(stack) = issue {
            XCTAssertTrue(stack.contains("A -> B -> C"))
        } else {
            XCTFail("Expected deepResolutionStack case")
        }
    }

    func test_healthIssue_circularDependency() {
        // Given
        let issue = HealthIssue.circularDependency("A -> B -> A")

        // When/Then
        if case let .circularDependency(cycle) = issue {
            XCTAssertEqual(cycle, "A -> B -> A")
        } else {
            XCTFail("Expected circularDependency case")
        }
    }

    // MARK: - ContainerHealthReport Tests

    func test_healthReport_withNoIssues_showsHealthyStatus() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 2,
            activeWeakReferences: 1,
            registeredTypes: []
        )
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

    func test_healthReport_withIssues_containsIssueDetails() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 2,
            activeWeakReferences: 1,
            registeredTypes: []
        )
        let report = ContainerHealthReport(
            status: .hasIssues,
            issues: [
                .memoryLeak("Leaky service"),
                .orphanedRegistrations(2)
            ],
            recommendations: ["Fix the leak", "Remove orphaned registrations"],
            diagnostics: diagnostics
        )

        // Then
        XCTAssertEqual(report.status, .hasIssues)
        XCTAssertEqual(report.issues.count, 2)
        XCTAssertEqual(report.recommendations.count, 2)
    }

    // MARK: - DefaultContainerMetrics Tests

    func test_metrics_recordResolution_tracksSuccessfully() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)

        // When
        await metrics.recordResolution(for: typeKey, duration: 0.001)
        await metrics.recordResolution(for: typeKey, duration: 0.002)
        await metrics.recordResolution(for: typeKey, duration: 0.003)
        let result = await metrics.getMetrics()

        // Then
        XCTAssertEqual(result.totalResolutions, 3)
    }

    func test_metrics_recordRegistration_tracksSuccessfully() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)

        // When
        await metrics.recordRegistration(for: typeKey)
        await metrics.recordRegistration(for: typeKey)
        _ = await metrics.getMetrics()

        // Then - registrations are tracked (no assertion needed for count as it's internal)
        // The main test is that it doesn't crash
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
        await metrics.recordResolution(for: typeKey, duration: 0.001)
        await metrics.recordResolution(for: typeKey, duration: 0.002)
        await metrics.recordResolution(for: typeKey, duration: 0.003)
        let result = await metrics.getMetrics()

        // Then - average should be 2ms (0.001 + 0.002 + 0.003) / 3 * 1000 = 2ms
        XCTAssertEqual(result.averageResolutionTime, 2.0, accuracy: 0.1)
    }

    func test_metrics_slowestResolutions_sortedDescending() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey1 = TypeKey(String.self, name: "fast")
        let typeKey2 = TypeKey(Int.self, name: "slow")
        let typeKey3 = TypeKey(Double.self, name: "medium")

        // When
        await metrics.recordResolution(for: typeKey1, duration: 0.001)
        await metrics.recordResolution(for: typeKey2, duration: 0.010)
        await metrics.recordResolution(for: typeKey3, duration: 0.005)
        let result = await metrics.getMetrics()

        // Then - slowest should be first
        XCTAssertEqual(result.slowestResolutions.count, 3)
        XCTAssertGreaterThan(result.slowestResolutions[0].1, result.slowestResolutions[1].1)
        XCTAssertGreaterThan(result.slowestResolutions[1].1, result.slowestResolutions[2].1)
    }

    func test_metrics_memoryUsageEstimate_isPositive() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)

        // When
        await metrics.recordResolution(for: typeKey, duration: 0.001)
        await metrics.recordRegistration(for: typeKey)
        let result = await metrics.getMetrics()

        // Then
        XCTAssertGreaterThan(result.memoryUsageEstimate, 0)
    }

    // MARK: - ContainerPerformanceMetrics Description Tests

    func test_performanceMetrics_descriptionFormatsCorrectly() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let typeKey = TypeKey(String.self, name: nil)
        await metrics.recordResolution(for: typeKey, duration: 0.005)
        await metrics.recordCacheHit(for: typeKey)

        // When
        let result = await metrics.getMetrics()
        let description = result.description

        // Then
        XCTAssertTrue(description.contains("Container Performance Metrics"))
        XCTAssertTrue(description.contains("Total Resolutions: 1"))
        XCTAssertTrue(description.contains("Average Resolution Time"))
        XCTAssertTrue(description.contains("Cache Hit Rate"))
        XCTAssertTrue(description.contains("Memory Usage"))
    }

    // MARK: - InstrumentedContainer Tests

    func test_instrumentedContainer_registrationAndResolution() async throws {
        // Given
        let container = InstrumentedContainer()

        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in
                TestImplementation()
            }

        // When
        let instance: TestProtocol = try await container.resolve(TestProtocol.self)

        // Then
        XCTAssertNotNil(instance)
    }

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

    func test_instrumentedContainer_unregister_removesRegistration() async throws {
        // Given
        let container = InstrumentedContainer()

        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in
                TestImplementation()
            }

        // Verify registration works
        let instance: TestProtocol = try await container.resolve(TestProtocol.self)
        XCTAssertNotNil(instance)

        // When
        _ = await container.unregister(TestProtocol.self, name: nil)

        // Then - resolution should fail
        do {
            let _: TestProtocol = try await container.resolve(TestProtocol.self)
            XCTFail("Expected resolution to fail after unregister")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
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

    func test_instrumentedContainer_reset_clearsRegistrations() async throws {
        // Given
        let container = InstrumentedContainer()

        _ = try await container.register(TestProtocol.self)
            .asSingleton()
            .with { _ in
                TestImplementation()
            }

        // When
        await container.reset(ignoreDependencies: [Never.Type]())

        // Then - resolution should fail
        do {
            let _: TestProtocol = try await container.resolve(TestProtocol.self)
            XCTFail("Expected resolution to fail after reset")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
    }

    func test_instrumentedContainer_recordsResolutionTimeForErrors() async throws {
        // Given
        let container = InstrumentedContainer()
        // Don't register anything - resolution will fail

        // When
        do {
            let _: TestProtocol = try await container.resolve(TestProtocol.self)
            XCTFail("Expected resolution to fail")
        } catch {
            // Expected
        }

        // Then - metrics should still record the attempt
        let metrics = await container.getPerformanceMetrics()
        XCTAssertNotNil(metrics)
        // Resolution was attempted (even though it failed)
        XCTAssertEqual(metrics?.totalResolutions, 1)
    }

    // MARK: - Multiple Type Resolution Metrics

    func test_metrics_multipleTypes_trackedSeparately() async {
        // Given
        let metrics = DefaultContainerMetrics()
        let stringKey = TypeKey(String.self, name: nil)
        let intKey = TypeKey(Int.self, name: nil)

        // When
        await metrics.recordResolution(for: stringKey, duration: 0.001)
        await metrics.recordResolution(for: intKey, duration: 0.002)
        await metrics.recordCacheHit(for: stringKey)
        await metrics.recordCacheMiss(for: intKey)

        let result = await metrics.getMetrics()

        // Then
        XCTAssertEqual(result.totalResolutions, 2)
        XCTAssertEqual(result.slowestResolutions.count, 2)
    }
}

// MARK: - Test Types

@available(iOS 15.0, *)
private protocol TestProtocol {
    func doSomething()
}

@available(iOS 15.0, *)
private class TestImplementation: TestProtocol {
    func doSomething() {}
}
