# CLAUDE.md - DI Framework

This file provides guidance to Claude Code when working with the Dependency Injection framework in the ComposableCheckout module.

## Overview

This is a modern, async-first dependency injection container designed for iOS 15+ applications. It follows SOLID principles and clean architecture patterns, providing thread-safe dependency management through Swift actors.

## Architecture

### Core Components

1. **Container.swift** - Main DI container implementation
   - Actor-based for thread safety
   - Supports three retention policies: transient, singleton, weak
   - Circular dependency detection with O(1) lookup
   - Memory management with automatic weak reference cleanup

2. **DIContainer.swift** - Global container management
   - Singleton pattern for app-wide access
   - Scoped containers for feature isolation
   - Mock container support for testing
   - Synchronous resolution for SwiftUI contexts

3. **ContainerProtocol.swift** - Protocol definitions
   - `Registrar`: Registration APIs
   - `DIResolver`: Resolution APIs (prefixed to avoid PromiseKit conflicts)
   - `LifecycleManager`: Container lifecycle management
   - `RegistrationBuilder`: Fluent API for configuration

4. **Factory.swift** - Modern factory pattern
   - Generic `Factory` protocol for parameterized creation
   - `SynchronousFactory` for performance optimization
   - Container extensions for factory registration

5. **RetentionStrategy.swift** - Strategy pattern implementation
   - `TransientStrategy`: New instance every time
   - `SingletonStrategy`: Strong reference caching
   - `WeakStrategy`: Weak reference with automatic cleanup

### Supporting Components

- **TypeKey.swift**: Type-safe dependency identification using ObjectIdentifier
- **ContainerError.swift**: Comprehensive error types with recovery suggestions
- **ContainerRetainPolicy.swift**: Enum defining retention policies
- **ContainerDiagnostics.swift**: Health monitoring and performance metrics
- **DependencyScope.swift**: Scoped container lifecycle management

### SwiftUI Integration

- **DIContainer+SwiftUI.swift**: Environment-based DI integration
- **SwiftUI+DI.swift**: View extensions and property wrappers
- Environment key for container access
- StateObject creation with DI fallback

## Usage Patterns

### Registration

```swift
// Singleton registration
_ = try await container.register(APIClient.self)
    .asSingleton()
    .with { _ in APIClient(baseURL: apiBaseURL) }

// Transient with dependencies
_ = try await container.register(PaymentService.self)
    .asTransient()
    .with { resolver in
        PaymentServiceImpl(
            apiClient: try await resolver.resolve(APIClient.self),
            logger: try await resolver.resolve(Logger.self)
        )
    }

// Named registration for multiple implementations
_ = try await container.register(Logger.self)
    .named("console")
    .asSingleton()
    .with { _ in ConsoleLogger() }

// Weak registration (only for reference types)
_ = try await container.register(CacheManager.self)
    .asWeak()
    .with { _ in CacheManager() }
```

### Resolution

```swift
// Async resolution (preferred)
let service = try await container.resolve(PaymentService.self)

// Sync resolution (for SwiftUI)
let service = try container.resolveSync(PaymentService.self)

// Named resolution
let logger = try await container.resolve(Logger.self, name: "console")

// Resolve all implementations
let processors = await container.resolveAll(PaymentProcessor.self)
```

### Factory Pattern

```swift
// Define factory
protocol PaymentMethodFactory: Factory {
    associatedtype Product = PaymentMethod
    associatedtype Params = PaymentMethodConfig
    
    func create(with params: PaymentMethodConfig) async throws -> PaymentMethod
}

// Register factory
_ = try await container.registerFactory(
    PaymentMethodFactoryImpl.self,
    policy: .singleton
) { resolver in
    PaymentMethodFactoryImpl(
        apiClient: try await resolver.resolve(APIClient.self)
    )
}

// Use factory
let factory = try await container.resolve(PaymentMethodFactoryImpl.self)
let paymentMethod = try await factory.create(with: config)
```

### SwiftUI Integration

```swift
// In PrimerCheckout.swift
.environment(\.diContainer, diContainer)

// In views
@Environment(\.diContainer) private var container

// StateObject with DI
@StateObject private var viewModel = DIContainer.stateObject(
    PaymentViewModel.self,
    default: PaymentViewModel()
)
```

## Best Practices

1. **Register Early, Resolve Late**: Set up all dependencies in CompositionRoot during app initialization
2. **Use Manual Resolution**: Explicit dependency resolution provides better control and error handling
3. **Prefer Protocol Registration**: Register protocols instead of concrete types for testability
4. **Handle Errors Gracefully**: Always handle potential resolution errors
5. **Use Scoped Containers**: Isolate feature-specific dependencies
6. **Avoid Property Wrappers**: This container uses manual resolution, not property wrapper injection

## Testing

```swift
// Create mock container
let mockContainer = await DIContainer.createMockContainer()

// Register mocks
_ = try await mockContainer.register(PaymentService.self)
    .asSingleton()
    .with { _ in MockPaymentService() }

// Use in tests
await DIContainer.withContainer(mockContainer) {
    // Test code runs with mock dependencies
}
```

## Diagnostics

```swift
// Get diagnostics
let diagnostics = await container.getDiagnostics()
diagnostics.printDetailedReport()

// Health check
let healthReport = await container.performHealthCheck()
healthReport.printReport()

// Performance monitoring
let instrumentedContainer = InstrumentedContainer()
// ... use container ...
await instrumentedContainer.printPerformanceReport()
```

## Common Patterns

### ViewModels with DI

```swift
class PaymentViewModel: ObservableObject {
    private let service: PaymentService
    
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        self.service = try await container.resolve(PaymentService.self)
    }
}
```

### Scoped Dependencies

```swift
class PaymentFlowScope: DependencyScope {
    let scopeId = "payment-flow"
    
    func setupContainer() async {
        guard let container = try? await getContainer() else { return }
        
        _ = try await container.register(PaymentFlowState.self)
            .asSingleton()
            .with { _ in PaymentFlowState() }
    }
}
```

## Important Notes

- **Thread Safety**: The container is actor-based and fully thread-safe
- **Async First**: Designed for async/await, with sync support for SwiftUI
- **No Circular Dependencies**: Automatic detection prevents circular references
- **Memory Efficient**: Weak references are automatically cleaned up
- **Type Safe**: Compile-time type checking with generics

## Current Status

The DI framework is being actively developed on the `bn/feature/stepByStepDI` branch. The main integration point is through `CompositionRoot.swift` which sets up all dependencies when `PrimerCheckout` initializes.