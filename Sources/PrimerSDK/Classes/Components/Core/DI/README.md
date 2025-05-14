# Primer.io iOS SDK - Dependency Injection Container

A powerful, async-first dependency injection container designed for modern iOS applications, following SOLID principles and clean architecture patterns.

## Features

- **🚀 Async/Await Support**: Full async support for modern Swift concurrency
- **🔄 Flexible Lifecycle Management**: Transient, Singleton, and Weak retention policies
- **🏭 Factory Pattern**: Support for parameterized object creation with Factory protocol
- **🎯 Property Wrapper Injection**: `@Injected` for automatic dependency resolution
- **🔍 Scoped Containers**: Context-aware dependency management
- **🧵 Thread-Safe**: Actor-based implementation for concurrent access
- **🔍 Type-Safe**: Compile-time type checking with generic protocols
- **🧪 Testing-Friendly**: Built-in mock container support

## Quick Start

### 1. Initialize the Container

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize the DI container
        Task {
            await DIContainer.setupMainContainer()
        }
        
        return true
    }
}
```

### 2. Register Dependencies

```swift
// Register dependencies in your app setup
await registerDependencies()

func registerDependencies() async {
    guard let container = await DIContainer.current else { return }
    
    // Register a singleton service
    _ = container.register(PaymentService.self)
        .asSingleton()
        .with { resolver in
            PaymentServiceImpl(
                apiClient: try await resolver.resolve(APIClient.self),
                keychain: try await resolver.resolve(KeychainService.self)
            )
        }
    
    // Register a transient repository
    _ = container.register(PaymentRepository.self)
        .asTransient()
        .with { resolver in
            PaymentRepositoryImpl(
                service: try await resolver.resolve(PaymentService.self)
            )
        }
    
    // Register with a name for multiple implementations
    _ = container.register(Logger.self)
        .named("console")
        .asSingleton()
        .with { _ in ConsoleLogger() }
}
```

### 3. Inject Dependencies

#### Using Property Wrapper (Recommended)

```swift
class PaymentViewModel: ObservableObject {
    @Injected private var paymentService: PaymentService
    @Injected private var repository: PaymentRepository
    @Injected(name: "console") private var logger: Logger
    @InjectedOptional private var analytics: AnalyticsService?
    
    func processPayment() async {
        logger.log("Processing payment...")
        
        do {
            let result = try await paymentService.process(amount: 100)
            analytics?.track("payment_success")
        } catch {
            logger.error("Payment failed: \(error)")
        }
    }
}
```

#### Manual Resolution

```swift
class PaymentUseCase {
    private let service: PaymentService
    private let logger: Logger
    
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        
        self.service = try await container.resolve(PaymentService.self)
        self.logger = try await container.resolve(Logger.self, name: "console")
    }
}
```

#### Using DIInjectable Protocol

```swift
class PaymentProcessor: DIInjectable {
    private let service: PaymentService
    private let validator: PaymentValidator
    
    required init(resolver: ContainerProtocol) throws {
        // Async resolution in sync context
        self.service = try await resolver.resolve(PaymentService.self)
        self.validator = try await resolver.resolve(PaymentValidator.self)
    }
}

// Usage
let processor = try await PaymentProcessor.create()
```

## Advanced Usage

### Factory Pattern

Use factories for objects that require parameters at creation time:

```swift
// Define a factory protocol
protocol PaymentMethodFactory: Factory {
    associatedtype Product = PaymentMethod
    associatedtype Params = PaymentMethodConfig
}

class PaymentMethodFactoryImpl: PaymentMethodFactory {
    func create(with config: PaymentMethodConfig) -> PaymentMethod {
        switch config.type {
        case .card:
            return CardPaymentMethod(config: config)
        case .applePay:
            return ApplePayMethod(config: config)
        case .paypal:
            return PayPalMethod(config: config)
        }
    }
}

// Register the factory
_ = container.register(PaymentMethodFactory.self)
    .asSingleton()
    .with { _ in PaymentMethodFactoryImpl() }

// Use the factory
guard let container = await DIContainer.current else { return }
let paymentMethod = try await container.create(
    factoryType: PaymentMethodFactory.self,
    with: PaymentMethodConfig(type: .card, settings: cardSettings)
)
```

### Async Factories

For factories that need async initialization:

```swift
protocol AsyncPaymentProcessorFactory: AsyncFactory {
    associatedtype Product = PaymentProcessor
    associatedtype Params = ProcessorConfig
}

class AsyncPaymentProcessorFactoryImpl: AsyncPaymentProcessorFactory {
    func create(with config: ProcessorConfig) async throws -> PaymentProcessor {
        // Async initialization
        let credentials = try await fetchCredentials(for: config.provider)
        return PaymentProcessor(config: config, credentials: credentials)
    }
}

// Usage
let processor = try await container.createAsync(
    factoryType: AsyncPaymentProcessorFactory.self,
    with: config
)
```

### Scoped Containers

Create isolated dependency scopes for specific features:

```swift
class PaymentFlowScope: DependencyScope {
    let scopeId = "payment-flow"
    
    func setupContainer() async {
        guard let container = try? await getContainer() else { return }
        
        // Register flow-specific dependencies
        _ = container.register(PaymentFlowState.self)
            .asSingleton()
            .with { _ in PaymentFlowState() }
        
        _ = container.register(PaymentStepValidator.self)
            .asTransient()
            .with { resolver in
                PaymentStepValidator(
                    state: try await resolver.resolve(PaymentFlowState.self)
                )
            }
    }
    
    func cleanupScope() async {
        // Cleanup logic
    }
}

// Usage
let scope = PaymentFlowScope()
await scope.register()

// Use scoped dependencies
try await scope.withContainer { container in
    let validator = try await container.resolve(PaymentStepValidator.self)
    return validator.validate(step: .cardDetails)
}

// Cleanup when done
await scope.unregister()
```

### Testing with Mock Container

```swift
class PaymentServiceTests: XCTestCase {
    var mockContainer: ContainerProtocol!
    
    override func setUp() async throws {
        mockContainer = await DIContainer.createMockContainer()
        
        // Register mocks
        _ = mockContainer.register(PaymentService.self)
            .asSingleton()
            .with { _ in MockPaymentService() }
        
        _ = mockContainer.register(Logger.self)
            .asSingleton()
            .with { _ in MockLogger() }
    }
    
    func testPaymentProcessing() async throws {
        await DIContainer.withContainer(mockContainer) {
            let viewModel = PaymentViewModel()
            await viewModel.processPayment()
            
            let mockService = try await mockContainer.resolve(PaymentService.self) as! MockPaymentService
            XCTAssertTrue(mockService.processWasCalled)
        }
    }
}
```

## Retention Policies

### Transient
Creates a new instance every time it's resolved:

```swift
_ = container.register(RequestLogger.self)
    .asTransient()
    .with { _ in RequestLogger() }
```

### Singleton
Creates one instance and reuses it throughout the app lifecycle:

```swift
_ = container.register(APIClient.self)
    .asSingleton()
    .with { _ in APIClient(baseURL: apiBaseURL) }
```

### Weak
Holds a weak reference, allowing the instance to be deallocated when no longer referenced:

```swift
_ = container.register(TemporaryCache.self)
    .asWeak()
    .with { _ in TemporaryCache() }
```

## Error Handling

The container provides comprehensive error handling:

```swift
do {
    let service = try await container.resolve(PaymentService.self)
} catch ContainerError.dependencyNotRegistered(let key) {
    print("Dependency not found: \(key)")
} catch ContainerError.circularDependency(let key, let path) {
    print("Circular dependency detected: \(path)")
} catch ContainerError.factoryFailed(let key, let error) {
    print("Factory failed for \(key): \(error)")
}
```

## Property Wrapper Options

### Error Handling Strategies

```swift
class SomeService {
    // Throw error on resolution failure (default)
    @Injected var requiredService: PaymentService
    
    // Use default value on failure
    @Injected(errorStrategy: .useDefault(MockPaymentService()))
    var serviceWithFallback: PaymentService
    
    // Log error and throw
    @Injected(errorStrategy: .logAndThrow)
    var debuggedService: PaymentService
    
    // Optional dependency (never throws)
    @InjectedOptional var optionalService: AnalyticsService?
}
```

### Lazy vs Eager Loading

```swift
class DataManager {
    // Lazy loading (default) - resolved on first access
    @Injected var lazyService: DataService
    
    // Eager loading - resolved during initialization
    @Injected(lazy: false) var eagerService: CacheService
}
```

## Best Practices

### 1. **Register Early, Resolve Late**
Register all dependencies during app launch, resolve them when needed.

### 2. **Use Property Wrappers for ViewModels**
Property wrappers make dependency injection seamless in SwiftUI and UIKit.

### 3. **Prefer Protocol Registration**
Register protocols instead of concrete types for better testability:

```swift
_ = container.register(PaymentServiceProtocol.self)
    .asSingleton()
    .with { _ in PaymentServiceImpl() }
```

### 4. **Use Scoped Containers for Feature Modules**
Isolate feature-specific dependencies in their own scopes.

### 5. **Keep Factory Parameters Simple**
Factory parameters should be simple value types or configuration objects.

### 6. **Handle Optional Dependencies Gracefully**
Use `@InjectedOptional` for dependencies that might not be available.

## Architecture Integration

### MVVM with Clean Architecture

```swift
// Domain Layer
protocol PaymentUseCase {
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult
}

// Use Case Implementation
class ProcessPaymentUseCase: PaymentUseCase, DIInjectable {
    private let repository: PaymentRepository
    private let validator: PaymentValidator
    
    required init(resolver: ContainerProtocol) throws {
        self.repository = try await resolver.resolve(PaymentRepository.self)
        self.validator = try await resolver.resolve(PaymentValidator.self)
    }
    
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult {
        try validator.validate(request)
        return try await repository.processPayment(request)
    }
}

// View Model
class PaymentViewModel: ObservableObject {
    @Injected private var useCase: PaymentUseCase
    @Published var state: PaymentState = .idle
    
    func processPayment(_ request: PaymentRequest) async {
        state = .processing
        
        do {
            let result = try await useCase.processPayment(request)
            state = .success(result)
        } catch {
            state = .failure(error)
        }
    }
}
```

## Performance Considerations

- **Actor-based Implementation**: Thread-safe without locks
- **Lazy Initialization**: Dependencies are created only when needed
- **Weak References**: Prevent memory leaks for temporary objects
- **Type Safety**: No runtime type checking overhead
- **Cached Resolution**: Singletons are cached for fast access

## Migration from Other DI Frameworks

### From Swinject

```swift
// Swinject
container.register(PaymentService.self) { r in
    PaymentServiceImpl(apiClient: r.resolve(APIClient.self)!)
}

// Primer DI
_ = container.register(PaymentService.self)
    .asSingleton()
    .with { resolver in
        PaymentServiceImpl(apiClient: try await resolver.resolve(APIClient.self))
    }
```

### From Resolver

```swift
// Resolver
@Injected var paymentService: PaymentService

// Primer DI (same syntax!)
@Injected var paymentService: PaymentService
```

## Integration with React Native

For React Native bridge integration:

```swift
@objc(PaymentSDK)
class PaymentSDK: NSObject {
    @Injected private var paymentService: PaymentService
    
    @objc
    func configureSDK(_ config: NSDictionary) {
        // SDK configuration
    }
    
    @objc
    func processPayment(_ paymentData: NSDictionary, 
                       resolver: @escaping RCTPromiseResolveBlock,
                       rejecter: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                let result = try await paymentService.process(paymentData)
                resolver(result.toDictionary())
            } catch {
                rejecter("PAYMENT_ERROR", error.localizedDescription, error)
            }
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **"Dependency not registered" Error**
   - Ensure the dependency is registered before resolution
   - Check the type and name match exactly

2. **"Circular dependency detected" Error**
   - Review your dependency graph
   - Consider using factories or breaking the circular reference

3. **"Container unavailable" Error**
   - Make sure `DIContainer.setupMainContainer()` is called
   - For testing, use `DIContainer.withContainer()`

4. **Property wrapper resolution timeouts**
   - Increase the timeout in `Injected` if needed
   - Prefer async resolution for complex dependency graphs

## Contributing

When contributing to the DI container:

1. Follow SOLID principles
2. Maintain async-first design
3. Add comprehensive tests
4. Update documentation
5. Ensure thread safety

## License

Copyright © 2025 Primer.io. All rights reserved.
