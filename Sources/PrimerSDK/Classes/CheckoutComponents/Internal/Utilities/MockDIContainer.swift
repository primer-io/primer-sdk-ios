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
  final class MockDIContainer: ContainerProtocol, @unchecked Sendable {
    private var registrations: [String: Any] = [:]

    /// Creates a mock DI container for previews
    /// - Parameter validationService: Custom validation service to use (defaults to PreviewValidationService with valid results)
    init(validationService: ValidationService = PreviewValidationService()) {
      // Register the provided validation service
      registrations["ValidationService"] = validationService
    }

    func register<T>(_ type: T.Type) -> any RegistrationBuilder<T> {
      fatalError("Not needed for preview mocks")
    }

    func unregister<T>(_ type: T.Type, name: String?) -> Self {
      self
    }

    func resolve<T>(_ type: T.Type, name: String?) async throws -> T {
      try resolveSync(type, name: name)
    }

    func resolveSync<T>(_ type: T.Type, name: String?) throws -> T {
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

    func resolveAll<T>(_ type: T.Type) async -> [T] {
      []
    }

    func reset<T>(ignoreDependencies: [T.Type]) async {}
  }

#endif  // DEBUG
