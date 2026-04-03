//
//  DependencyScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol DependencyScope: AnyObject {
  var scopeId: String { get }
  func setupContainer(_ container: any ContainerProtocol) async
  func cleanupScope() async
}

@available(iOS 15.0, *)
extension DependencyScope {

  func register() async {
    let container = Container()
    await setupContainer(container)
    await DIContainer.setScopedContainer(container, for: scopeId)
  }

  func unregister() async {
    await DIContainer.removeScopedContainer(for: scopeId)
    await cleanupScope()
  }

  func getContainer() async throws -> any ContainerProtocol {
    guard let container = await DIContainer.scopedContainer(for: scopeId) else {
      throw ContainerError.scopeNotFound(scopeId)
    }
    return container
  }

  func withContainer<T>(_ action: (any ContainerProtocol) async throws -> T) async throws -> T {
    let container = try await getContainer()
    return try await action(container)
  }
}
