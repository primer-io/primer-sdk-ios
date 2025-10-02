//
//  ValidationServiceDiagnostics.swift
//
//
//  Created by Boris on 2.10.25..
//

import Foundation

/**
 * Diagnostics and monitoring utilities for ValidationService and ValidationResultCache
 *
 * This file contains health check, performance benchmarking, and metrics functionality
 * separated from the core validation logic to keep the main implementation clean.
 *
 * ## What's Included:
 * - `ValidationCacheMetrics`: Real-time cache performance metrics structure
 * - `getCacheMetrics()`: Extension method to retrieve cache metrics
 * - `performServiceHealthCheck()`: Comprehensive validation service health check
 * - `benchmarkValidationPerformance()`: Performance benchmarking utilities
 * - `ValidationServiceHealthReport`: Health check results structure
 * - `ValidationPerformanceBenchmark`: Benchmark results structure
 *
 * ## Quick Start:
 *
 * ### Monitor Cache Performance
 * ```swift
 * let metrics = ValidationResultCache.shared.getCacheMetrics()
 * print(metrics.performanceSummary)
 * ```
 *
 * ### Run Health Check
 * ```swift
 * #if DEBUG
 * let service = DefaultValidationService()
 * let report = service.performServiceHealthCheck()
 * print(report.summary)
 * #endif
 * ```
 */

// MARK: - Cache Metrics

/// INTERNAL HELPER: Metrics structure for validation cache performance
///
/// Contains real-time performance metrics for the validation result cache,
/// including hit/miss statistics, cache usage, and timing information.
///
/// ## Interpreting Metrics
///
/// - **Hit Rate**: Percentage of validations served from cache
///   - **Good**: 70-85% (expected for typical user input)
///   - **Low**: <50% (may indicate cache is too small or TTL too short)
///   - **High**: >90% (excellent - most validations are cached)
///
/// - **Average Validation Time**: Time taken for cache misses
///   - **Typical**: 0.1-0.5ms for simple validations
///   - **Slow**: >1ms (may indicate complex validation rules)
///
/// - **Cache Usage**: Current entries vs maximum capacity
///   - Monitor to ensure cache isn't constantly full (would cause evictions)
///
/// ## Example Usage
/// ```swift
/// let metrics = ValidationResultCache.shared.getCacheMetrics()
/// print(metrics.performanceSummary)
/// // Check individual properties
/// if metrics.hitRate > 0.8 {
///     print("✅ Cache is performing well")
/// }
/// ```
internal struct ValidationCacheMetrics {
    /// Total number of cache hits (validations served from cache)
    let totalHits: Int

    /// Total number of cache misses (validations requiring computation)
    let totalMisses: Int

    /// Current number of entries stored in cache (approximate)
    let currentEntries: Int

    /// Maximum number of entries the cache can hold
    let maxEntries: Int

    /// Cache hit rate (0.0 to 1.0, where 1.0 = 100% hit rate)
    let hitRate: Double

    /// Average time spent on validation for cache misses (in seconds)
    let averageValidationTime: TimeInterval

    /// Human-readable performance summary
    ///
    /// Returns a formatted string with cache performance statistics suitable
    /// for logging or debugging output.
    ///
    /// Example output (from benchmark with repeated test data):
    /// ```
    /// Validation Cache Performance:
    /// - Hit Rate: 85.2% (852 hits, 148 misses)
    /// - Cache Usage: 12/200 entries
    /// - Average Validation Time: 0.15ms
    /// ```
    ///
    /// - Note: Hit rate varies by scenario. During normal typing: 10-30% (each keystroke = new input).
    ///   During benchmarks/tests: 70-95% (repeated test data). During form corrections: 40-60%.
    var performanceSummary: String {
        let hitRatePercent = String(format: "%.1f", hitRate * 100)
        let avgTimeMs = String(format: "%.2f", averageValidationTime * 1000)

        return """
        Validation Cache Performance:
        - Hit Rate: \(hitRatePercent)% (\(totalHits) hits, \(totalMisses) misses)
        - Cache Usage: \(currentEntries)/\(maxEntries) entries
        - Average Validation Time: \(avgTimeMs)ms
        """
    }
}

// MARK: - Cache Metrics Extension

extension ValidationResultCache {
    /// INTERNAL UTILITY: Provides cache performance metrics for monitoring and debugging
    ///
    /// Returns real-time cache performance metrics including hit rate, total requests,
    /// and average validation time. Useful for performance tuning and diagnostics.
    ///
    /// ## Usage Examples
    ///
    /// ### Debug Logging
    /// ```swift
    /// #if DEBUG
    /// let metrics = ValidationResultCache.shared.getCacheMetrics()
    /// print(metrics.performanceSummary)
    /// // Example output (from benchmark scenario):
    /// // Validation Cache Performance:
    /// // - Hit Rate: 85.2% (852 hits, 148 misses)
    /// // - Cache Usage: 12/200 entries
    /// // - Average Validation Time: 0.15ms
    /// #endif
    /// ```
    ///
    /// ### Performance Monitoring
    /// ```swift
    /// let metrics = ValidationResultCache.shared.getCacheMetrics()
    /// if metrics.hitRate < 0.5 && metrics.totalHits > 100 {
    ///     print("⚠️ Cache hit rate is low: \(metrics.hitRate)")
    /// }
    /// ```
    ///
    /// ### Analytics Integration
    /// ```swift
    /// let metrics = ValidationResultCache.shared.getCacheMetrics()
    /// AnalyticsService.track("validation_cache_stats", [
    ///     "hit_rate": metrics.hitRate,
    ///     "total_requests": metrics.totalHits + metrics.totalMisses
    /// ])
    /// ```
    ///
    /// - Returns: `ValidationCacheMetrics` containing current cache performance data
    /// - Note: This method is thread-safe and can be called from any thread
    /// - SeeAlso: `performServiceHealthCheck()` for automated health monitoring
    func getCacheMetrics() -> ValidationCacheMetrics {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        let hits = totalHits
        let misses = totalMisses
        let entries = currentEntries
        let totalRequests = hits + misses
        let hitRate = totalRequests > 0 ? Double(hits) / Double(totalRequests) : 0.0
        let avgValidationTime = misses > 0 ? totalValidationTime / Double(misses) : 0.0

        return ValidationCacheMetrics(
            totalHits: hits,
            totalMisses: misses,
            currentEntries: entries,
            maxEntries: maxEntries,
            hitRate: hitRate,
            averageValidationTime: avgValidationTime
        )
    }
}

// MARK: - Health Check Reports

/// INTERNAL HELPER: Health report structure for validation service
internal struct ValidationServiceHealthReport {
    let isHealthy: Bool
    let issues: [String]
    let warnings: [String]
    let cacheMetrics: ValidationCacheMetrics

    var summary: String {
        let status = isHealthy ? "✅ Healthy" : "❌ Issues Found"
        let issuesList = issues.isEmpty ? "None" : issues.joined(separator: ", ")
        let warningsList = warnings.isEmpty ? "None" : warnings.joined(separator: ", ")

        return """
        Validation Service Health Report:
        Status: \(status)
        Issues: \(issuesList)
        Warnings: \(warningsList)

        \(cacheMetrics.performanceSummary)
        """
    }
}

/// INTERNAL HELPER: Performance benchmark results
internal struct ValidationPerformanceBenchmark {
    let averageValidationTimes: [String: TimeInterval]
    let totalIterations: Int

    var summary: String {
        let sortedTimes = averageValidationTimes.sorted { $0.value < $1.value }
        let timingResults = sortedTimes.map { key, time in
            "\(key): \(String(format: "%.4f", time * 1000))ms"
        }.joined(separator: "\n")

        return """
        Validation Performance Benchmark (\(totalIterations) iterations):
        \(timingResults)
        """
    }
}

// MARK: - Validation Service Diagnostics Extension

extension DefaultValidationService {
    // MARK: - Internal Quality Enhancement Methods

    /// INTERNAL UTILITY: Validates service configuration and reports issues
    ///
    /// Performs comprehensive health checks on the validation service, including
    /// testing core validation rules, checking cache performance, and validating
    /// all field types for proper configuration.
    ///
    /// ## When to Use
    ///
    /// - During app startup in debug builds to verify validation is working
    /// - In automated testing to ensure validation rules are properly configured
    /// - When debugging validation issues to identify configuration problems
    /// - Periodically in production (debug builds) to monitor cache performance
    ///
    /// ## Example Usage
    ///
    /// ### Debug Build Startup Check
    /// ```swift
    /// #if DEBUG
    /// let validationService = DefaultValidationService()
    /// let healthReport = validationService.performServiceHealthCheck()
    /// print(healthReport.summary)
    ///
    /// if !healthReport.isHealthy {
    ///     assertionFailure("Validation service has critical issues")
    /// }
    /// #endif
    /// ```
    ///
    /// ### Unit Testing
    /// ```swift
    /// func testValidationServiceHealth() {
    ///     let service = DefaultValidationService()
    ///     let report = service.performServiceHealthCheck()
    ///     XCTAssertTrue(report.isHealthy, "Validation service should be healthy")
    ///     XCTAssertTrue(report.issues.isEmpty, "Should have no critical issues")
    /// }
    /// ```
    ///
    /// ### Monitoring Cache Performance
    /// ```swift
    /// let report = validationService.performServiceHealthCheck()
    /// let hitRate = report.cacheMetrics.hitRate
    /// if hitRate < 0.5 && report.cacheMetrics.totalHits > 100 {
    ///     print("⚠️ Warning: Low cache hit rate detected: \(hitRate)")
    /// }
    /// ```
    ///
    /// - Returns: `ValidationServiceHealthReport` containing health status, issues, warnings, and cache metrics
    /// - Note: This method performs actual validations and may take a few milliseconds to complete
    /// - SeeAlso: `getCacheMetrics()` for cache-only performance metrics
    func performServiceHealthCheck() -> ValidationServiceHealthReport {
        var issues: [String] = []
        var warnings: [String] = []

        // Verify rules factory is configured correctly with test card number
        let testCardNumber = "4111111111111111" // Valid Visa test card
        let cardNumberRule = rulesFactory.createCardNumberRule(allowedCardNetworks: nil)
        let testResult = cardNumberRule.validate(testCardNumber)

        if !testResult.isValid {
            issues.append("Card number rule is not working correctly - test validation failed")
        }

        // Check cache performance and warn if hit rate is poor
        let cacheMetrics = ValidationResultCache.shared.getCacheMetrics()
        if cacheMetrics.hitRate < 0.5 && cacheMetrics.totalHits > 100 {
            warnings.append("Cache hit rate is below 50% - consider tuning cache strategy")
        }

        // Verify all required field types reject nil values
        let allFieldTypes: [PrimerInputElementType] = [
            .cardNumber, .expiryDate, .cvv, .cardholderName,
            .postalCode, .countryCode, .firstName, .lastName,
            .addressLine1, .city, .state
        ]

        for fieldType in allFieldTypes {
            let result = validateField(type: fieldType, value: nil)
            if result.isValid && fieldType != .addressLine2 {
                warnings.append("Field type \(fieldType.rawValue) allows nil values unexpectedly")
            }
        }

        return ValidationServiceHealthReport(
            isHealthy: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            cacheMetrics: cacheMetrics
        )
    }

    /// INTERNAL HELPER: Performance benchmarking for validation operations
    ///
    /// Runs 1000 iterations of each validation type and returns average execution times.
    /// Useful for performance regression testing and optimization.
    ///
    /// - Returns: Benchmark results with average validation times per field type
    func benchmarkValidationPerformance() -> ValidationPerformanceBenchmark {
        let iterations = 1000
        var results: [String: TimeInterval] = [:]

        // Benchmark card number validation with multiple card types
        let cardNumbers = ["4111111111111111", "5555555555554444", "378282246310005"]
        let cardStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            for cardNumber in cardNumbers {
                _ = validateCardNumber(cardNumber)
            }
        }
        let cardEndTime = CFAbsoluteTimeGetCurrent()
        results["cardNumber"] = (cardEndTime - cardStartTime) / Double(iterations * cardNumbers.count)

        // Benchmark CVV validation
        let cvvStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = validateCVV("123", cardNetwork: .visa)
        }
        let cvvEndTime = CFAbsoluteTimeGetCurrent()
        results["cvv"] = (cvvEndTime - cvvStartTime) / Double(iterations)

        // Benchmark expiry date validation
        let expiryStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = validateExpiry(month: "12", year: "25")
        }
        let expiryEndTime = CFAbsoluteTimeGetCurrent()
        results["expiry"] = (expiryEndTime - expiryStartTime) / Double(iterations)

        return ValidationPerformanceBenchmark(
            averageValidationTimes: results,
            totalIterations: iterations
        )
    }
}
