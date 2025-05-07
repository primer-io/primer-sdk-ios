//
//  defining.swift
//  
//
//  Created by Boris on 7. 5. 2025..
//


# Swift DI Framework

This is a comprehensive Dependency Injection framework for Swift applications, designed to provide clean, flexible, and testable dependency management.

## Key Features

- **Thread-safe** dependency resolution
- **Multiple retention policies** (default, strong, weak)
- **Named dependencies** for multiple implementations of the same protocolfork
- **Factory support** for creating instances with runtime parameters
- **Circular dependency detection**
- **Improved error handling** with multiple strategies
- **Modular registration** with a clean DSL
- **Hybrid approach** supporting both property wrapper and constructor injection
- **Testing support** with container swapping

## Files Overview

- **ContainerProtocol.swift** - Core protocol defining DI container functionality
- **ContainerRetainPolicy.swift** - Enum defining retention policies
- **ContainerError.swift** - Error types for the DI system
- **Container.swift** - Main container implementation
- **DIContainer.swift** - Global container management
- **Injected.swift** - Property wrapper for dependency injection
- **Factory.swift** - Protocol for parameterized instance creation
- **DIInjectable.swift** - Protocol for constructor-based injection
- **ExampleUsage.swift** - Comprehensive examples

## Usage Examples

### 1. Application Setup

Set up your container at application launch:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Set up the main container
    DIContainer.setupMainContainer()
    return true
}
```

### 2. Dependency Registration

Register your dependencies in modules:

```swift
container.module("Services") { container in
    // Register AuthService as a singleton
    container.register(AuthServiceProtocol.self, with: .strong) { _ in
        AuthService()
    }
    
    // Register with a name (for multiple implementations)
    container.register(NetworkMonitorProtocol.self, name: "cellular") { _ in
        CellularNetworkMonitor()
    }
}
```

### 3. Property Wrapper Injection

Use the `@Injected` property wrapper for simple cases:

```swift
class AuthService: AuthServiceProtocol {
    @Injected private var networkMonitor: NetworkMonitorProtocol
    
    // For named dependencies:
    @Injected(name: "cellular") private var cellularMonitor: NetworkMonitorProtocol
    
    // With error handling:
    @Injected(errorStrategy: .useDefault(MockNetworkMonitor())) private var safeMonitor: NetworkMonitorProtocol
}
```

### 4. Constructor Injection

Use constructor injection for better testability:

```swift
class ProfileViewModel: DIViewModel {
    private let userRepository: UserRepositoryProtocol
    private let authService: AuthServiceProtocol
    
    required init(resolver: ContainerProtocol) {
        self.userRepository = try! resolver.resolve()
        self.authService = try! resolver.resolve()
        super.init(resolver: resolver)
    }
    
    // For testing
    init(userRepository: UserRepositoryProtocol, authService: AuthServiceProtocol) {
        self.userRepository = userRepository
        self.authService = authService
        super.init(resolver: DIContainer.current!)
    }
}

// Usage
let viewModel = ProfileViewModel.create() // Uses DIContainer.current
```

### 5. Factory Pattern

Create instances with parameters:

```swift
protocol UserFactoryProtocol: Factory where Product == User, Params == (name: String, email: String) {}

class UserFactory: UserFactoryProtocol {
    func create(with params: (name: String, email: String)) -> User {
        return User(id: UUID().uuidString, name: params.name, email: params.email)
    }
}

// Usage
let userFactory: UserFactoryProtocol = try container.resolve()
let user = userFactory.create(with: (name: "John", email: "john@example.com"))

// Or directly:
let user: User = try container.create(with: (name: "John", email: "john@example.com"))
```

### 6. Testing with Container Swapping

Easily swap containers for testing:

```swift
func testWithTemporaryContainer() {
    // Create a test container
    let testContainer = Container()
    
    // Register test dependencies
    testContainer.register(UserRepositoryProtocol.self) { _ in MockUserRepository() }
    
    // Use the withContainer method
    DIContainer.withContainer(testContainer) {
        let viewModel = ProfileViewModel.create()
        // Test with container-created viewModel
    }
}
```

## Best Practices

1. Prefer constructor injection for better testability and explicit dependencies
2. Use the property wrapper for simple cases or when modifying existing code
3. Use strong retention only for true singletons
4. Group related registrations in modules
5. Create dedicated factory types for complex object creation
6. Use named dependencies sparingly and with clear naming
7. When testing, prefer direct dependency mocking over container swapping
