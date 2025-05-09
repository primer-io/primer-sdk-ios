# Swift DI Framework

A comprehensive Dependency Injection framework for Swift applications built with modern Swift features including actors and async/await support. Designed to provide clean, flexible, and testable dependency management.

## Key Features

- **Thread-safe using Swift Actors** - eliminates race conditions with modern concurrency
- **Multiple lifecycle policies** (transient, singleton, weak, scoped)
- **Named dependencies** for multiple implementations of the same protocol
- **Type-safe dependency keys** using ObjectIdentifier
- **Factory support** for creating instances with runtime parameters
- **Async/await support** for asynchronous dependency resolution
- **Circular dependency detection** with detailed resolution paths
- **Enhanced error handling** with multiple strategies
- **Dependency scopes** for granular control over instance lifecycles
- **Modular registration** with a chainable DSL
- **Hybrid approach** supporting both property wrapper and constructor injection
- **Testing support** with container swapping
- **Detailed logging** integrated with PrimerLogger
- **Diagnostic tools** for dependency graph visualization and validation

## Files Overview

- **TypeKey.swift** - Type-safe key structure for dependency identification
- **ContainerProtocol.swift** - Core protocol defining DI container functionality with async support
- **ContainerRetainPolicy.swift** - Enum defining lifecycle policies including scopes
- **ContainerError.swift** - Enhanced error types for better diagnostics
- **Container.swift** - Main container implementation as a Swift actor
- **Logger.swift** - Logging integration with PrimerLogger
- **DIContainer.swift** - Global container management with async support
- **Injected.swift** - Property wrappers for dependency injection (async and sync)
- **Factory.swift** - Protocols for parameterized instance creation, including async factories
- **DIInjectable.swift** - Protocols for constructor-based injection

## Usage Examples

### 1. Application Setup

Set up your container at application launch:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Set up the main container
    Task {
        await DIContainer.setupMainContainer()
    }
    return true
}
```

### 2. Dependency Registration

Register your dependencies using the new chainable API:

```swift
await container.module("Services") { container in
    // Register as a singleton
    container.singleton(type: AuthServiceProtocol.self) { resolver in
        AuthService()
    }
    
    // Register with a name and specific lifecycle
    container.register(type: NetworkMonitorProtocol.self, name: "cellular", with: .default) { _ in
        CellularNetworkMonitor()
    }
    
    // Register in a specific scope
    container.scoped(type: UserSessionProtocol.self, in: "session") { _ in
        UserSession()
    }
}
```

### 3. Property Wrapper Injection

Use the `@Injected` property wrapper for async injection:

```swift
class AuthService: AuthServiceProtocol {
    @Injected private var networkMonitor: NetworkMonitorProtocol
    
    // For named dependencies:
    @Injected(name: "cellular") private var cellularMonitor: NetworkMonitorProtocol
    
    // With error handling:
    @Injected(errorStrategy: .useDefault(MockNetworkMonitor())) private var safeMonitor: NetworkMonitorProtocol
    
    func authenticate() async throws {
        // Access dependencies
        let monitor = networkMonitor
        // ...
    }
}
```

For synchronous contexts, use `@SyncInjected`:

```swift
class LegacyService {
    @SyncInjected private var dataStore: DataStoreProtocol
    
    func fetchData() -> Data {
        return dataStore.getData()
    }
}
```

### 4. Constructor Injection

Use constructor injection for better testability with async support:

```swift
class ProfileViewModel: DIViewModel {
    private let userRepository: UserRepositoryProtocol
    private let authService: AuthServiceProtocol
    
    required init(resolver: any ContainerProtocol) async throws {
        self.userRepository = try await resolver.resolve()
        self.authService = try await resolver.resolve()
        try await super.init(resolver: resolver)
    }
    
    // For testing
    init(userRepository: UserRepositoryProtocol, authService: AuthServiceProtocol) async throws {
        self.userRepository = userRepository
        self.authService = authService
        try await super.init(resolver: await DIContainer.current!)
    }
}

// Usage
let viewModel = try await ProfileViewModel.create()
```

For synchronous contexts:

```swift
class LegacyViewModel: DISyncViewModel {
    private let userRepository: UserRepositoryProtocol
    
    required init(resolver: any ContainerProtocol) {
        self.userRepository = try! resolver.resolveSync()
        super.init(resolver: resolver)
    }
}

// Usage
let viewModel = LegacyViewModel.create()
```

### 5. Factory Pattern

Create instances with parameters using async factories:

```swift
protocol UserFactoryProtocol: AsyncFactory where Product == User, Params == (name: String, email: String) {}

class UserFactory: UserFactoryProtocol {
    func create(with params: (name: String, email: String)) async throws -> User {
        return User(id: UUID().uuidString, name: params.name, email: params.email)
    }
}

// Usage
let userFactory: UserFactoryProtocol = try await container.resolve()
let user = try await userFactory.create(with: (name: "John", email: "john@example.com"))

// Or directly:
let user: User = try await container.createAsync(params: (name: "John", email: "john@example.com"))
```

### 6. Scoped Dependencies

Create and manage dependency scopes:

```swift
// Create a session scope
let sessionScope = try container.createScope("userSession")

// Register a dependency in that scope
container.scoped(type: UserPreferencesProtocol.self, in: "userSession") { _ in
    UserPreferences()
}

// Resolve from the scope
let preferences = try await container.resolve(type: UserPreferencesProtocol.self)

// Release the scope when done
container.releaseScope("userSession")
```

### 7. Testing with Container Swapping

Easily swap containers for testing:

```swift
func testWithTemporaryContainer() async throws {
    // Create a test container
    let testContainer = Container()
    
    // Register test dependencies
    await testContainer.register(type: UserRepositoryProtocol.self) { _ in
        MockUserRepository()
    }
    
    // Use the withContainer method
    try await DIContainer.withContainer(testContainer) {
        let viewModel = try await ProfileViewModel.create()
        // Test with container-created viewModel
    }
}
```

### 8. Diagnostic Tools

Visualize and validate the dependency graph:

```swift
// Get a visualization of the dependency graph
let graph = await container.dependencyGraph()
print(graph)

// Validate dependencies
let issues = await container.validateDependencies()
if !issues.isEmpty {
    print("Dependency issues found:")
    issues.forEach { print($0) }
}
```

## Best Practices

1. Prefer constructor injection (`DIInjectable`) for better testability and explicit dependencies
2. Use the property wrapper for simple cases or when modifying existing code
3. Use singleton lifecycle only for true singletons
4. Group related registrations in modules
5. Create dedicated factory types for complex object creation
6. Use named dependencies sparingly and with clear naming
7. Take advantage of async/await for cleaner dependency resolution
8. Use scopes to manage groups of related dependencies
9. Leverage the diagnostic tools to validate your dependency graph
10. When testing, prefer direct dependency mocking over container swapping

## Future Improvements

- Swift Macros support for reducing boilerplate (pending Swift 6 adoption)
- Integration with SwiftUI's environment system
- Additional diagnostic and visualization tools
- Performance optimizations for large dependency graphs
