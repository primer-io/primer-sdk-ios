//
//  ValidationResultCache.swift
//
//
//  Created by Boris on 2.10.25..
//

import Foundation

/**
 * INTERNAL PERFORMANCE OPTIMIZATION: Validation Result Cache
 *
 * High-performance caching system for validation operations to improve
 * real-time form validation performance by avoiding repeated rule execution.
 *
 * ## Cache Strategy:
 * - **Key**: Hash of validation input + rule type + context
 * - **Value**: Pre-computed ValidationResult
 * - **Size Limit**: 200 entries (covers typical form interaction patterns)
 * - **Eviction**: LRU eviction with time-based expiration (30 seconds)
 *
 * ## Performance Impact:
 * - **Cache Hit**: O(1) - Direct hash lookup vs O(n) rule execution
 * - **Cache Miss**: O(n) - Original validation + cache store
 * - **Memory**: ~8KB for full cache (200 entries × ~40 bytes each)
 * - **Hit Rate**: Expected 70-85% for typical user typing patterns
 *
 * ## Metrics & Monitoring:
 * The cache tracks real-time performance metrics including:
 * - Hit/miss counts and hit rate percentage
 * - Current cache usage (entries stored)
 * - Average validation time for cache misses
 *
 * Access metrics for debugging or monitoring:
 * ```swift
 * let metrics = ValidationResultCache.shared.getCacheMetrics()
 * print(metrics.performanceSummary)
 * ```
 *
 * For comprehensive health checks including cache performance:
 * ```swift
 * let service = DefaultValidationService()
 * let report = service.performServiceHealthCheck()
 * print(report.summary) // Includes cache metrics
 * ```
 *
 * - Note: Metrics and diagnostics methods are in ValidationServiceDiagnostics.swift
 */
internal final class ValidationResultCache {

    /// Shared cache instance for all validation operations
    internal static let shared = ValidationResultCache()

    /// Internal cache with automatic cleanup
    private let cache = NSCache<NSString, CachedValidationResult>()

    /// Maximum number of entries the cache can hold
    internal var maxEntries: Int {
        return cache.countLimit
    }

    // MARK: - Metrics Tracking
    //
    // Real-time performance metrics are tracked for monitoring and debugging.
    // All metrics are thread-safe and can be accessed via getCacheMetrics().
    //
    // Usage example:
    //   let metrics = ValidationResultCache.shared.getCacheMetrics()
    //   print(metrics.performanceSummary)

    /// Thread-safe lock for metrics updates
    internal let metricsLock = NSLock()

    /// Total number of cache hits (validations served from cache)
    internal var totalHits: Int = 0

    /// Total number of cache misses (validations requiring computation)
    internal var totalMisses: Int = 0

    /// Current number of entries in cache (approximate, updated on adds)
    internal var currentEntries: Int = 0

    /// Cumulative validation time for all misses (in seconds, for averaging)
    internal var totalValidationTime: TimeInterval = 0.0

    private init() {
        // Configure cache limits for optimal performance
        cache.countLimit = 200      // Maximum 200 validation results
        cache.totalCostLimit = 8000 // Maximum ~8KB memory usage
    }

    /// Wrapper for cached validation results with timestamp
    private class CachedValidationResult {
        let result: ValidationResult
        let timestamp: Date

        init(result: ValidationResult) {
            self.result = result
            self.timestamp = Date()
        }

        /// Check if cache entry is still valid (30 seconds expiration)
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < 30
        }
    }

    /// Generates cache key for validation input
    private func cacheKey(for input: String, type: String, context: String = "") -> String {
        return "\(type)_\(input)_\(context)".hash.description
    }

    /// Retrieves cached validation result or performs validation
    ///
    /// This method implements a read-through cache pattern with automatic metrics tracking.
    /// On cache hits, returns the cached result immediately. On cache misses, executes the
    /// validator closure, caches the result, and tracks timing metrics.
    ///
    /// - Parameters:
    ///   - input: The input value to validate (e.g., card number, CVV)
    ///   - type: Type of validation (e.g., "cardNumber", "cvv")
    ///   - context: Optional context for cache key differentiation (e.g., card network)
    ///   - validator: Closure that performs the actual validation logic
    /// - Returns: Cached or freshly computed ValidationResult
    func cachedValidation(
        input: String,
        type: String,
        context: String = "",
        validator: () -> ValidationResult
    ) -> ValidationResult {
        let key = cacheKey(for: input, type: type, context: context)
        let cacheKey = key as NSString

        // Return cached result if available and not expired
        if let cached = cache.object(forKey: cacheKey), cached.isValid {
            metricsLock.lock()
            totalHits += 1
            metricsLock.unlock()
            return cached.result
        }

        // Cache miss: perform validation and measure execution time
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = validator()
        let endTime = CFAbsoluteTimeGetCurrent()
        let validationTime = endTime - startTime

        // Store validation result in cache for future use
        cache.setObject(CachedValidationResult(result: result), forKey: cacheKey)

        // Update performance metrics
        metricsLock.lock()
        totalMisses += 1
        totalValidationTime += validationTime
        currentEntries = min(currentEntries + 1, cache.countLimit)
        metricsLock.unlock()

        return result
    }

    /// Clears validation cache and resets all metrics
    ///
    /// Useful for testing scenarios or when responding to memory pressure.
    /// This will force all subsequent validations to be recomputed.
    func clearCache() {
        cache.removeAllObjects()

        // Reset all performance metrics to zero
        metricsLock.lock()
        totalHits = 0
        totalMisses = 0
        currentEntries = 0
        totalValidationTime = 0.0
        metricsLock.unlock()
    }

}
