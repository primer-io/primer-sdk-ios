//
//  DIInjectable.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Protocol for types that can be initialized with a DI container
public protocol DIInjectable {
    /// Initialize with a dependency resolver
    /// - Parameter resolver: The container that provides access to dependencies
    init(resolver: ContainerProtocol) throws
}

public extension DIInjectable {
    /// Create an instance using the current container
    /// - Returns: A new instance with dependencies from the current container
    /// - Throws: ContainerError if resolution fails
    static func create() async throws -> Self {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        return try Self(resolver: container)
    }

    /// Create an instance with a custom container
    /// - Parameter container: The container to use for dependency resolution
    /// - Returns: A new instance with dependencies from the specified container
    /// - Throws: ContainerError if resolution fails
    static func create(with container: ContainerProtocol) throws -> Self {
        return try Self(resolver: container)
    }
}

/// A base class that implements DIInjectable
open class DIInjectableObject: DIInjectable {
    /// Required initializer for DIInjectable conformance
    /// Override this in subclasses to resolve dependencies
    public required init(resolver: ContainerProtocol) throws {
        // Default empty implementation
        // Subclasses should override this and resolve their dependencies
    }
}

/// Base class for ViewModels with DI support
open class DIViewModel: DIInjectableObject {
    // Add common ViewModel functionality here
}

/// Base class for Repositories with DI support
open class DIRepository: DIInjectableObject {
    // Add common Repository functionality here
}

/// Base class for Services with DI support
open class DIService: DIInjectableObject {
    // Add common Service functionality here
}

/// Base class for UseCases with DI support
open class DIUseCase: DIInjectableObject {
    // Add common UseCase functionality here
}
