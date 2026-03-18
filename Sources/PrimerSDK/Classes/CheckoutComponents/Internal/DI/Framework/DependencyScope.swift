//
//  DependencyScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Protocol defining a scoped dependency container lifecycle
public protocol DependencyScope: AnyObject {
  var scopeId: String { get }
  func setupContainer() async
  func cleanupScope() async
}

@available(iOS 15.0, *)
extension DependencyScope {

  public func register() async {
    let container = Container()
    await setupContainer()
    await DIContainer.setScopedContainer(container, for: scopeId)
  }

  public func unregister() async {
    await DIContainer.removeScopedContainer(for: scopeId)
    await cleanupScope()
  }

  public func getContainer() async throws -> ContainerProtocol {
    guard let container = await DIContainer.scopedContainer(for: scopeId) else {
      throw ContainerError.scopeNotFound(scopeId)
    }
    return container
  }

  public func withContainer<T>(_ action: (ContainerProtocol) async throws -> T) async throws -> T {
    let container = try await getContainer()
    return try await action(container)
  }
}
