//
//  DIContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
@MainActor
final class DIContainer: LogReporter {
  static let shared = DIContainer()

  /// Isolated actor for thread-safe container operations
  private actor ContainerStorage {
    var container: (any ContainerProtocol)?
    var scopedContainers: [String: (any ContainerProtocol)] = [:]

    init(container: (any ContainerProtocol)? = nil) {
      self.container = container
    }

    func getContainer() -> (any ContainerProtocol)? {
      container
    }

    func setContainer(_ newContainer: (any ContainerProtocol)?) {
      container = newContainer
    }

    /// Atomically installs `newContainer` and returns the previous one in a single actor hop.
    func swap(to newContainer: (any ContainerProtocol)?) -> (any ContainerProtocol)? {
      let previous = container
      container = newContainer
      return previous
    }

    func getScopedContainer(for scopeId: String) -> (any ContainerProtocol)? {
      scopedContainers[scopeId]
    }

    func setScopedContainer(_ container: (any ContainerProtocol), for scopeId: String) {
      scopedContainers[scopeId] = container
    }

    func removeScopedContainer(for scopeId: String) {
      scopedContainers[scopeId] = nil
    }
  }

  private let storage: ContainerStorage

  static var current: (any ContainerProtocol)? {
    get async {
      await shared.storage.getContainer()
    }
  }

  /// Access to the current container (synchronous)
  /// Note: This uses a cached reference that is updated when the container changes
  static var currentSync: (any ContainerProtocol)? {
    shared.cachedContainer
  }

  /// Cached reference to the current container for synchronous access
  private var cachedContainer: (any ContainerProtocol)?

  private init() {
    let container = Container()
    storage = ContainerStorage(container: container)
    cachedContainer = container
  }

  static func createContainer() -> any ContainerProtocol {
    Container()
  }

  static func setContainer(_ container: any ContainerProtocol) async {
    await shared.storage.setContainer(container)
    shared.cachedContainer = container
  }

  static func clearContainer() async {
    await shared.storage.setContainer(nil)
    shared.cachedContainer = nil
  }

  static func setupMainContainer() async {
    let container = Container()
    await registerDependencies(in: container)
    await setContainer(container)
  }

  /// Executes a block with a temporary container, restoring the previous one afterward.
  ///
  /// Intended for single-context test scoping (setUp / test / tearDown). It is **not** safe under
  /// concurrent container mutation: `cachedContainer` (main-actor) and the backing storage actor are
  /// distinct sources of truth, so a concurrent `setContainer`/`withContainer` during `action` can
  /// make the restore observe a stale snapshot. Drive it from one task at a time.
  ///
  /// - Parameters:
  ///   - container: The container to use during the execution of the action
  ///   - action: The closure to execute with the temporary container
  /// - Returns: The result of the action
  /// - Throws: Any error thrown by the action
  @discardableResult
  static func withContainer<T>(
    _ container: any ContainerProtocol,
    perform action: () async throws -> T
  ) async rethrows -> T {
    let previousSync = shared.cachedContainer
    let previous = await shared.storage.swap(to: container)
    shared.cachedContainer = container

    do {
      let result = try await action()
      await shared.storage.setContainer(previous)
      shared.cachedContainer = previousSync
      return result
    } catch {
      await shared.storage.setContainer(previous)
      shared.cachedContainer = previousSync
      throw error
    }
  }

  static func setScopedContainer(_ container: any ContainerProtocol, for scopeId: String)
    async {
    await shared.storage.setScopedContainer(container, for: scopeId)
  }

  static func scopedContainer(for scopeId: String) async -> (any ContainerProtocol)? {
    await shared.storage.getScopedContainer(for: scopeId)
  }

  static func removeScopedContainer(for scopeId: String) async {
    await shared.storage.removeScopedContainer(for: scopeId)
  }

  private static func registerDependencies(in container: Container) async {
    _ = try? await container.register(ContainerProtocol.self).asSingleton().with { $0 }
  }
}
