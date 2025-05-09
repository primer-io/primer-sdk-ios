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
    init(resolver: any ContainerProtocol) async throws
}

/// Protocol for types that can be initialized with a DI container synchronously
protocol DISyncInjectable {
    /// Initialize with a dependency resolver
    /// - Parameter resolver: The container that provides access to dependencies
    init(resolver: any ContainerProtocol)
}

extension DIInjectable {
    /// Create an instance using the current container
    /// - Returns: A new instance with dependencies from the current container
    static func create() async throws -> Self {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerTerminated
        }
        return try await Self(resolver: container)
    }
    
    /// Create an instance with a custom container
    /// - Parameter container: The container to use for dependency resolution
    /// - Returns: A new instance with dependencies from the specified container
    static func create(with container: any ContainerProtocol) async throws -> Self {
        return try await Self(resolver: container)
    }
    
    /// Create an instance with a scoped container
    /// - Parameter scopeId: The scope identifier
    /// - Returns: A new instance with dependencies from the scoped container
    static func create(in scopeId: String) async throws -> Self {
        guard let container = await DIContainer.scopedContainer(for: scopeId) else {
            throw ContainerError.scopeNotFound(scopeId)
        }
        return try await Self(resolver: container)
    }
}

extension DISyncInjectable {
    /// Create an instance using the current container
    /// - Returns: A new instance with dependencies from the current container
    static func create() -> Self {
        guard let container = DIContainer.currentSync else {
            fatalError("No DI container available - make sure DIContainer.setupMainContainer() is called during app initialization")
        }
        return Self(resolver: container)
    }
    
    /// Create an instance with a custom container
    /// - Parameter container: The container to use for dependency resolution
    /// - Returns: A new instance with dependencies from the specified container
    static func create(with container: any ContainerProtocol) -> Self {
        return Self(resolver: container)
    }
}

/// A base class that implements DIInjectable
class DIInjectableObject: DIInjectable {
    /// Required initializer for DIInjectable conformance
    /// Override this in subclasses to resolve dependencies
    required init(resolver: any ContainerProtocol) async throws {
        // Default empty implementation
        // Subclasses should override this and resolve their dependencies
    }
}

/// A base class that implements DISyncInjectable
class DISyncInjectableObject: DISyncInjectable {
    /// Required initializer for DISyncInjectable conformance
    /// Override this in subclasses to resolve dependencies
    required init(resolver: any ContainerProtocol) {
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

/// Base class for ViewModels with synchronous DI support
class DISyncViewModel: DISyncInjectableObject {
    // Add common ViewModel functionality here
}

/// Base class for Repositories with synchronous DI support
class DISyncRepository: DISyncInjectableObject {
    // Add common Repository functionality here
}

/// Base class for Services with synchronous DI support
class DISyncService: DISyncInjectableObject {
    // Add common Service functionality here
}

/// Base class for UseCases with synchronous DI support
class DISyncUseCase: DISyncInjectableObject {
    // Add common UseCase functionality here
}

#if compiler(>=6.0)
// Swift 6 macros support
@attached(peer, names: named(create))
public macro Injectable() = #externalMacro(module: "DIKit", type: "InjectableMacro")

@attached(accessor, names: unnamed)
public macro Inject<T>(_ type: T.Type = T.self, name: String? = nil) = #externalMacro(module: "DIKit", type: "InjectMacro")
#endif
