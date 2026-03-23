//
//  RetentionStrategy.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol RetentionStrategy: Sendable {
  func instance(
    for key: TypeKey,
    registration: Container.FactoryRegistration,
    in container: Container
  ) async throws -> Any
}

struct TransientStrategy: RetentionStrategy {
  func instance(
    for key: TypeKey,
    registration: Container.FactoryRegistration,
    in container: Container
  ) async throws -> Any {
    try await registration.buildAsync(container)
  }
}

struct SingletonStrategy: RetentionStrategy {
  func instance(
    for key: TypeKey,
    registration: Container.FactoryRegistration,
    in container: Container
  ) async throws -> Any {
    if let stored = await container.instances[key] {
      return stored
    }
    let new = try await registration.buildAsync(container)
    // Double-check: another task may have resolved while we awaited the factory
    if let stored = await container.instances[key] {
      return stored
    }
    await container.setInstance(new, forKey: key)
    return new
  }
}

struct WeakStrategy: RetentionStrategy {
  func instance(
    for key: TypeKey,
    registration: Container.FactoryRegistration,
    in container: Container
  ) async throws -> Any {
    if let box = await container.weakBoxes[key], let obj = box.instance {
      return obj
    }
    let any = try await registration.buildAsync(container)
    // we only register class instances under `.weak`
    let obj = any as AnyObject
    await container.setWeakBox(WeakBox(obj), forKey: key)
    return obj
  }
}
