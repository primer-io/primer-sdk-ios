//
//  MockDIContainer.swift
//  PrimerSDK - CheckoutComponents
//
//  Created for SwiftUI Preview support
//

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
        return self
    }

    public func resolve<T>(_ type: T.Type, name: String?) async throws -> T {
        return try resolveSync(type, name: name)
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
        return []
    }

    public func reset<T>(ignoreDependencies: [T.Type]) async {}
}

#endif // DEBUG
