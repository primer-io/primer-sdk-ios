//
//  ContainerDiagnostics.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct ContainerDiagnostics: Sendable, CustomStringConvertible {
    public let totalRegistrations: Int
    public let singletonInstances: Int
    public let weakReferences: Int
    public let activeWeakReferences: Int
    public let registeredTypes: [TypeKey]

    public var description: String {
        """
        Container Diagnostics:
        - Total Registrations: \(totalRegistrations)
        - Singleton Instances: \(singletonInstances)
        - Weak References: \(weakReferences) (active: \(activeWeakReferences))
        - Memory Efficiency: \(String(format: "%.1f", Double(activeWeakReferences) / max(Double(weakReferences), 1.0) * 100))%
        """
    }

    public func printDetailedReport() {
        print(description)
        print("\nRegistered Types:")
        for type in registeredTypes.sorted(by: { $0.description < $1.description }) {
            print("  - \(type)")
        }
    }
}

public enum HealthStatus {
    case healthy
    case hasIssues
    case critical
}

public enum HealthIssue {
    case memoryLeak(String)
    case orphanedRegistrations(Int)
    case deepResolutionStack(String)
    case circularDependency(String)
}

public struct ContainerHealthReport {
    public let status: HealthStatus
    public let issues: [HealthIssue]
    public let recommendations: [String]
    public let diagnostics: ContainerDiagnostics

    public func printReport() {
        print("🔍 Container Health Report")
        print("Status: \(status)")

        if !issues.isEmpty {
            print("\n⚠️ Issues Found:")
            for issue in issues {
                print("  - \(issue)")
            }
        }

        if !recommendations.isEmpty {
            print("\n💡 Recommendations:")
            for recommendation in recommendations {
                print("  - \(recommendation)")
            }
        }

        print("\n📊 Diagnostics:")
        print(diagnostics.description)
    }
}

// MARK: - Instrumented Container (Wrapper Pattern)

/// Container with performance monitoring capabilities using wrapper pattern
public actor InstrumentedContainer: ContainerProtocol {
    private let container: Container
    private let metrics: ContainerMetrics?

    public init(
        metrics: ContainerMetrics? = DefaultContainerMetrics(),
        logger: @escaping (String) -> Void = { _ in }
    ) {
        self.container = Container()
        self.metrics = metrics
    }

    public nonisolated func register<T>(_ type: T.Type) -> any RegistrationBuilder<T> {
        return container.register(type)
    }

    @discardableResult
    public func unregister<T>(_ type: T.Type, name: String?) async -> InstrumentedContainer {
        await container.unregister(type, name: name)
        return self
    }

    public func resolve<T>(_ type: T.Type, name: String? = nil) async throws -> T {
        let key = TypeKey(type, name: name)
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let result = try await container.resolve(type, name: name)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            await metrics?.recordResolution(for: key, duration: duration)
            return result
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            await metrics?.recordResolution(for: key, duration: duration)
            throw error
        }
    }

    public nonisolated func resolveSync<T>(_ type: T.Type, name: String? = nil) throws -> T {
        return try container.resolveSync(type, name: name)
    }

    public func resolveAll<T>(_ type: T.Type) async -> [T] {
        return await container.resolveAll(type)
    }

    public func reset<T>(ignoreDependencies: [T.Type]) async {
        await container.reset(ignoreDependencies: ignoreDependencies)
    }

    public func getPerformanceMetrics() async -> ContainerPerformanceMetrics? {
        return await metrics?.getMetrics()
    }

    public func printPerformanceReport() async {
        if let metricsReport = await getPerformanceMetrics() {
            print(metricsReport.description)
        }
    }
}

// MARK: - Container Metrics Protocol (minimal implementation for InstrumentedContainer)

public protocol ContainerMetrics: Sendable {
    func recordResolution(for key: TypeKey, duration: TimeInterval) async
    func recordRegistration(for key: TypeKey) async
    func recordCacheHit(for key: TypeKey) async
    func recordCacheMiss(for key: TypeKey) async
    func getMetrics() async -> ContainerPerformanceMetrics
}

public struct ContainerPerformanceMetrics: Sendable {
    public let totalResolutions: Int
    public let averageResolutionTime: TimeInterval
    public let slowestResolutions: [(TypeKey, TimeInterval)]
    public let cacheHitRate: Double
    public let memoryUsageEstimate: Int

    public var description: String {
        """
        Container Performance Metrics:
        - Total Resolutions: \(totalResolutions)
        - Average Resolution Time: \(String(format: "%.3f", averageResolutionTime))ms
        - Cache Hit Rate: \(String(format: "%.1f", cacheHitRate * 100))%
        - Memory Usage: ~\(memoryUsageEstimate) bytes

        Slowest Resolutions:
        \(slowestResolutions.prefix(5).map { "  \($0.0): \(String(format: "%.3f", $0.1))ms" }.joined(separator: "\n"))
        """
    }
}

public actor DefaultContainerMetrics: ContainerMetrics {
    private var resolutionTimes: [TypeKey: [TimeInterval]] = [:]
    private var registrationCounts: [TypeKey: Int] = [:]
    private var cacheHits: [TypeKey: Int] = [:]
    private var cacheMisses: [TypeKey: Int] = [:]

    public init() {}

    public func recordResolution(for key: TypeKey, duration: TimeInterval) {
        resolutionTimes[key, default: []].append(duration)
    }

    public func recordRegistration(for key: TypeKey) {
        registrationCounts[key, default: 0] += 1
    }

    public func recordCacheHit(for key: TypeKey) {
        cacheHits[key, default: 0] += 1
    }

    public func recordCacheMiss(for key: TypeKey) {
        cacheMisses[key, default: 0] += 1
    }

    public func getMetrics() -> ContainerPerformanceMetrics {
        let totalResolutions = resolutionTimes.values.map { $0.count }.reduce(0, +)
        let totalTime = resolutionTimes.values.flatMap { $0 }.reduce(0, +)
        let averageTime = totalResolutions > 0 ? totalTime / Double(totalResolutions) : 0

        // Calculate cache hit rate
        let totalHits = cacheHits.values.reduce(0, +)
        let totalMisses = cacheMisses.values.reduce(0, +)
        let hitRate = (totalHits + totalMisses) > 0 ? Double(totalHits) / Double(totalHits + totalMisses) : 0

        // Find slowest resolutions
        var slowest: [(TypeKey, TimeInterval)] = []
        for (key, times) in resolutionTimes {
            if let maxTime = times.max() {
                slowest.append((key, maxTime))
            }
        }
        slowest.sort { $0.1 > $1.1 }

        // Estimate memory usage (rough calculation)
        let memoryEstimate = resolutionTimes.count * 64 + // TypeKey overhead
            totalResolutions * 8 + // TimeInterval storage
            registrationCounts.count * 64

        return ContainerPerformanceMetrics(
            totalResolutions: totalResolutions,
            averageResolutionTime: averageTime * 1000, // Convert to ms
            slowestResolutions: slowest,
            cacheHitRate: hitRate,
            memoryUsageEstimate: memoryEstimate
        )
    }
}
