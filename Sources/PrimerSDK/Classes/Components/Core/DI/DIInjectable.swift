//
//  DIInjectable.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Protocol for types that can be initialized with a DI container
protocol DIInjectable {
    /// Initialize with a dependency resolver
    /// - Parameter resolver: The container that provides access to dependencies
    init(resolver: ContainerProtocol)
}

extension DIInjectable {
    /// Create an instance using the current container
    /// - Returns: A new instance with dependencies from the current container
    static func create() async -> Self {
        guard let container = await DIContainer.current else {
            fatalError("No DI container available - make sure DIContainer.setupMainContainer() is called during app initialization")
        }
        return Self(resolver: container)
    }

    /// Create an instance with a custom container
    /// - Parameter container: The container to use for dependency resolution
    /// - Returns: A new instance with dependencies from the specified container
    static func create(with container: ContainerProtocol) -> Self {
        return Self(resolver: container)
    }
}

/// A base class that implements DIInjectable
class DIInjectableObject: DIInjectable {
    /// Required initializer for DIInjectable conformance
    /// Override this in subclasses to resolve dependencies
    required init(resolver: ContainerProtocol) {
        // Default empty implementation
        // Subclasses should override this and resolve their dependencies
    }
}

/// Base class for ViewModels with DI support
class DIViewModel: DIInjectableObject {
    // Add common ViewModel functionality here
}

/// Base class for Repositories with DI support
class DIRepository: DIInjectableObject {
    // Add common Repository functionality here
}

/// Base class for Services with DI support
class DIService: DIInjectableObject {
    // Add common Service functionality here
}

/// Base class for UseCases with DI support
class DIUseCase: DIInjectableObject {
    // Add common UseCase functionality here
}
