//
//  Container.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length

import Foundation

final class WeakBox<T: AnyObject> {
  weak var instance: T?
  init(_ inst: T) { instance = inst }
}

/// Thread-safe cache for resolved singletons, accessible without actor isolation.
/// Prevents DispatchSemaphore deadlocks in resolveSync by serving
/// already-resolved singletons synchronously.
final class SyncCache: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [TypeKey: Any] = [:]

  func get<T>(_ type: T.Type, name: String? = nil) -> T? {
    let key = TypeKey(type, name: name)
    lock.lock()
    defer { lock.unlock() }
    return storage[key] as? T
  }

  func set(_ value: Any, forKey key: TypeKey) {
    lock.lock()
    defer { lock.unlock() }
    storage[key] = value
  }

  func clear() {
    lock.lock()
    defer { lock.unlock() }
    storage.removeAll()
  }
}

/// Thread-safe container for storing values across async boundaries
final class ThreadSafeContainer<T>: @unchecked Sendable {
  private let lock = NSLock()
  private var _value: T?

  var value: T? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _value
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _value = newValue
    }
  }
}

actor Container: ContainerProtocol, LogReporter {
  struct FactoryRegistration: Sendable {
    let policy: ContainerRetainPolicy
    let buildAsync: @Sendable (ContainerProtocol) async throws -> Any

    init(
      policy: ContainerRetainPolicy,
      buildAsync: @escaping @Sendable (ContainerProtocol) async throws -> Any
    ) {
      self.policy = policy
      self.buildAsync = buildAsync
    }

    init(
      policy: ContainerRetainPolicy,
      buildSync: @escaping @Sendable (ContainerProtocol) throws -> Any
    ) {
      self.policy = policy
      buildAsync = { container in
        try buildSync(container)
      }
    }
  }

  final class ContainerRegistrationBuilderImpl<T>: RegistrationBuilder, @unchecked Sendable {
    private let container: Container
    private let type: T.Type
    private var name: String?
    private var policy: ContainerRetainPolicy = .transient

    fileprivate init(container: Container, type: T.Type) {
      self.container = container
      self.type = type
    }

    @discardableResult
    public func named(_ name: String) -> Self {
      self.name = name
      return self
    }

    @discardableResult
    public func asSingleton() -> Self {
      policy = .singleton
      return self
    }

    @discardableResult
    public func asWeak() -> Self {
      policy = .weak
      return self
    }

    @discardableResult
    public func asTransient() -> Self {
      policy = .transient
      return self
    }

    @discardableResult
    public func with(
      _ factory: @escaping @Sendable (any ContainerProtocol) async throws -> T
    ) async throws -> Self {
      try await container.registerInternal(type: type, name: name, with: policy) { resolver in
        try await factory(resolver)
      }
      return self
    }

    @discardableResult
    public func with(
      _ factory: @escaping @Sendable (any ContainerProtocol) throws -> T
    ) async throws -> Self {
      try await container.registerInternal(type: type, name: name, with: policy) { resolver in
        try factory(resolver)
      }
      return self
    }
  }

  // MARK: - Properties

  private var factories: [TypeKey: FactoryRegistration] = [:]
  private var instances: [TypeKey: Any] = [:]
  private var weakBoxes: [TypeKey: WeakBox<AnyObject>] = [:]
  /// O(1) circular dependency detection
  private var resolutionStack: Set<TypeKey> = []
  private var resolutionOrder: [TypeKey] = []

  /// Nonisolated thread-safe cache for resolved singletons.
  /// Allows resolveSync to return immediately without blocking
  /// the calling thread when the singleton is already available.
  private nonisolated let syncCache = SyncCache()

  func setInstance(_ instance: Any, forKey key: TypeKey) {
    instances[key] = instance
    syncCache.set(instance, forKey: key)
  }

  func setWeakBox(_ box: WeakBox<AnyObject>, forKey key: TypeKey) {
    weakBoxes[key] = box
  }

  func getInstance(forKey key: TypeKey) -> Any? { instances[key] }
  func getWeakBox(forKey key: TypeKey) -> WeakBox<AnyObject>? { weakBoxes[key] }

  // MARK: - Registration

  @discardableResult
  public nonisolated func register<T>(_ type: T.Type) -> any RegistrationBuilder<T> {
    ContainerRegistrationBuilderImpl(container: self, type: type)
  }

  private func registerInternal<T>(
    type: T.Type,
    name: String?,
    with policy: ContainerRetainPolicy,
    factory: @escaping (ContainerProtocol) async throws -> T
  ) throws {
    let key = TypeKey(type, name: name)

    // Validate weak policy for non-class types
    if policy == .weak, !(T.self is AnyObject.Type) {
      throw ContainerError.weakUnsupported(key)
    }

    // Clean up any existing instances
    instances.removeValue(forKey: key)
    weakBoxes.removeValue(forKey: key)

    // Register the new factory
    factories[key] = FactoryRegistration(policy: policy) { container in
      try await factory(container)
    }
  }

  public nonisolated func registerIfNeeded<T>(_ type: T.Type, name: String? = nil) async
    -> ContainerRegistrationBuilderImpl<T>? {
    let key = TypeKey(type, name: name)
    let isRegistered = await isRegistered(key)

    guard !isRegistered else {
      // Already registered
      return nil
    }

    let builder = ContainerRegistrationBuilderImpl(container: self, type: type)
    return name != nil ? builder.named(name!) : builder
  }

  private func isRegistered(_ key: TypeKey) -> Bool {
    factories[key] != nil
  }

  @discardableResult
  public func unregister<T>(_ type: T.Type, name: String? = nil) async -> Self {
    unregisterInternal(type, name: name)
    return self
  }

  private func unregisterInternal<T>(_ type: T.Type, name: String?) {
    let key = TypeKey(type, name: name)

    // Remove factory and instances
    factories.removeValue(forKey: key)
    instances.removeValue(forKey: key)
    weakBoxes.removeValue(forKey: key)
  }

  // MARK: - Resolution

  public func resolve<T>(_ type: T.Type, name: String? = nil) async throws -> T {
    let key = TypeKey(type, name: name)

    guard let registration = factories[key] else {
      throw ContainerError.dependencyNotRegistered(key)
    }

    // O(1) circular dependency detection
    if resolutionStack.contains(key) {
      throw ContainerError.circularDependency(key, path: resolutionOrder + [key])
    }

    resolutionStack.insert(key)
    resolutionOrder.append(key)

    defer {
      resolutionStack.remove(key)
      resolutionOrder.removeLast()
    }

    do {
      // Delegate to the correct strategy
      let instance = try await strategy(for: registration.policy)
        .instance(for: key, registration: registration, in: self)

      guard let typed = instance as? T else {
        throw ContainerError.typeCastFailed(key, expected: String(describing: T.self), actual: String(describing: Swift.type(of: instance)))
      }

      return typed
    } catch let containerError as ContainerError {
      throw containerError
    } catch {
      throw ContainerError.factoryFailed(key, underlyingError: error)
    }
  }

  /// Synchronous resolution for SwiftUI and other sync contexts.
  /// First checks the nonisolated sync cache for already-resolved singletons
  /// to avoid blocking the main thread. Falls back to semaphore-based
  /// resolution with timeout for first-time resolution.
  ///
  /// - Warning: The semaphore-based fallback blocks the calling thread while
  ///   waiting for actor-isolated async work. If called from the Swift
  ///   cooperative thread pool (e.g. inside a `Task`) this can deadlock
  ///   because the blocked thread may be the only one available to run
  ///   the actor hop. Always call from the main thread or a non-cooperative
  ///   dispatch queue, and prefer the async `resolve(_:name:)` when possible.
  nonisolated func resolveSync<T>(_ type: T.Type, name: String? = nil) throws -> T {
    // Fast path: check nonisolated cache for already-resolved singletons
    if let cached: T = syncCache.get(type, name: name) {
      return cached
    }

    // Slow path: resolve via actor with semaphore (only for first-time resolution)
    // Task.detached avoids inheriting @MainActor from the caller, which would
    // deadlock: main blocked by semaphore while Task waits for main to run.
    let semaphore = DispatchSemaphore(value: 0)
    let resultContainer = ThreadSafeContainer<Result<T, Error>>()

    Task.detached { [self] in
      do {
        let resolved = try await resolve(type, name: name)
        resultContainer.value = .success(resolved)
      } catch {
        resultContainer.value = .failure(error)
      }
      semaphore.signal()
    }

    let timeoutResult = semaphore.wait(timeout: .now() + 0.5)

    let finalResult = resultContainer.value

    guard timeoutResult == .success, let finalResult else {
      throw ContainerError.factoryFailed(
        TypeKey(type, name: name),
        underlyingError: NSError(
          domain: "DIContainer", code: -1,
          userInfo: [
            NSLocalizedDescriptionKey: "Synchronous resolution timed out"
          ]
        )
      )
    }

    switch finalResult {
    case let .success(value):
      return value
    case let .failure(error):
      throw error
    }
  }

  /// Resolve multiple dependencies concurrently
  public func resolveBatch<T>(_ requests: [(type: T.Type, name: String?)]) async throws -> [T] {
    try await withThrowingTaskGroup(of: (Int, T).self) { group in
      for (index, request) in requests.enumerated() {
        group.addTask {
          let result = try await self.resolve(request.type, name: request.name)
          return (index, result)
        }
      }

      var results: [(Int, T)] = []
      for try await result in group {
        results.append(result)
      }

      // Sort by original order
      results.sort { $0.0 < $1.0 }
      return results.map(\.1)
    }
  }

  // MARK: - Strategy Pattern

  private func strategy(for policy: ContainerRetainPolicy) -> RetentionStrategy {
    policy.makeStrategy()
  }

  // MARK: - Resolve All

  public func resolveAll<T>(_ type: T.Type) async -> [T] {
    var result: [T] = []

    // 1) Strong instances
    for value in instances.values {
      if let cast = value as? T {
        result.append(cast)
      }
    }

    // 2) Weak instances (filter out nil references)
    for box in weakBoxes.values {
      if let inst = box.instance as? T {
        result.append(inst)
      }
    }

    // 3) Non-transient factories not yet built
    for (key, registration) in factories where registration.policy != .transient {
      // Skip if already in strong or weak storage
      guard !instances.keys.contains(key),
        !weakBoxes.keys.contains(key)
      else {
        continue
      }

      // Build it and cast if possible
      if let any = try? await strategy(for: registration.policy)
        .instance(for: key, registration: registration, in: self),
        let cast = any as? T {
        result.append(cast)
      }
    }

    return result
  }

  // MARK: - Container Lifecycle

  /// Reset all dependencies except those specified
  public func reset<T>(ignoreDependencies: [T.Type] = []) async {
    // Build a set of keys to skip during reset
    let keysToIgnore = Set(ignoreDependencies.map { TypeKey($0) })

    // Reset strong instances except the ones to ignore
    for key in instances.keys where !keysToIgnore.contains(key) {
      instances.removeValue(forKey: key)
    }

    // Weak instances
    for key in weakBoxes.keys where !keysToIgnore.contains(key) {
      weakBoxes.removeValue(forKey: key)
    }

    // Reset factories except the ones to ignore
    for key in factories.keys where !keysToIgnore.contains(key) {
      factories.removeValue(forKey: key)
    }

    // Clear the nonisolated sync cache
    syncCache.clear()
  }

  // MARK: - Memory Management

  private func cleanupWeakReferences() {
    weakBoxes = weakBoxes.compactMapValues { box in
      box.instance != nil ? box : nil
    }
  }

  /// Call during low-memory warnings
  public func performMaintenanceCleanup() {
    cleanupWeakReferences()
  }

  // MARK: - Factory Registration

  public nonisolated func registerFactory<F: Factory>(_ factory: F) async throws -> Self {
    _ = try await register(F.self)
      .asSingleton()
      .with { _ in factory }
    return self
  }

  // MARK: - Diagnostics

  /// Get diagnostic information about the container state
  public func getDiagnostics() -> ContainerDiagnostics {
    cleanupWeakReferences()  // Clean before reporting

    return ContainerDiagnostics(
      totalRegistrations: factories.count,
      singletonInstances: instances.count,
      weakReferences: weakBoxes.count,
      activeWeakReferences: weakBoxes.values.compactMap(\.instance).count,
      registeredTypes: Array(factories.keys)
    )
  }

  /// Perform health check on the container
  public func performHealthCheck() -> ContainerHealthReport {
    let diagnostics = getDiagnostics()
    var issues: [HealthIssue] = []
    var recommendations: [String] = []

    // Check for memory issues
    if diagnostics.weakReferences > 0 {
      let efficiency = Double(diagnostics.activeWeakReferences) / Double(diagnostics.weakReferences)
      if efficiency < 0.7 {
        issues.append(
          .memoryLeak("Low weak reference efficiency: \(String(format: "%.1f", efficiency * 100))%")
        )
        recommendations.append("Consider calling performMaintenanceCleanup() more frequently")
      }
    }

    // Check for orphaned registrations
    let unusedRegistrations = factories.count - diagnostics.singletonInstances
    if unusedRegistrations > diagnostics.totalRegistrations / 2 {
      issues.append(.orphanedRegistrations(unusedRegistrations))
      recommendations.append("Remove unused registrations to improve performance")
    }

    // Check circular dependencies (simplified)
    if resolutionOrder.count > 10 {
      issues.append(.deepResolutionStack("Resolution stack depth: \(resolutionOrder.count)"))
      recommendations.append("Consider breaking complex dependency chains")
    }

    return ContainerHealthReport(
      status: issues.isEmpty ? .healthy : .hasIssues,
      issues: issues,
      recommendations: recommendations,
      diagnostics: diagnostics
    )
  }
}

// swiftlint:enable file_length
