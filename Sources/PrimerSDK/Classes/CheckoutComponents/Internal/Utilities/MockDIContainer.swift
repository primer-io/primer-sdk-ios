//
//  MockDIContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if DEBUG
  import SwiftUI

  /// Mock implementation of ContainerProtocol for SwiftUI previews
  /// Provides basic dependency resolution for preview environments
  @available(iOS 15.0, *)
  public class MockDIContainer: ContainerProtocol {
    private var registrations: [String: Any] = [:]

    /// Creates a mock DI container for previews
    /// - Parameter validationService: Custom validation service to use (defaults to MockValidationService with valid results)
    public init(validationService: ValidationService = MockValidationService()) {
      // Register the provided validation service
      registrations["ValidationService"] = validationService
    }

    public func register<T>(_ type: T.Type) -> any RegistrationBuilder<T> {
      fatalError("Not needed for preview mocks")
    }

    public func unregister<T>(_ type: T.Type, name: String?) -> Self {
      self
    }

    public func resolve<T>(_ type: T.Type, name: String?) async throws -> T {
      try resolveSync(type, name: name)
    }

    public func resolveSync<T>(_ type: T.Type, name: String?) throws -> T {
      let key = String(describing: type)
      guard let instance = registrations[key] as? T else {
        throw NSError(
          domain: "MockDIContainer",
          code: 404,
          userInfo: [NSLocalizedDescriptionKey: "Type not registered: \(key)"]
        )
      }
      return instance
    }

    public func resolveAll<T>(_ type: T.Type) async -> [T] {
      []
    }

    public func reset<T>(ignoreDependencies: [T.Type]) async {}
  }

#endif  // DEBUG
