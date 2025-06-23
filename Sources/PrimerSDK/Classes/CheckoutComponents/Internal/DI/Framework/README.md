# Primer.io iOS SDK - Dependency Injection Container

A powerful, async-first dependency injection container designed for modern iOS applications, following SOLID principles and clean architecture patterns.

## Features

- **🚀 Async/Await Support**: Full async support for modern Swift concurrency
- **🔄 Flexible Lifecycle Management**: Transient, Singleton, and Weak retention policies  
- **🏭 Factory Pattern**: Support for parameterized object creation with Factory protocol
- **🎯 Manual Resolution**: Explicit, controlled dependency resolution with async/sync support
- **🔍 Scoped Containers**: Context-aware dependency management
- **🧵 Thread-Safe**: Actor-based implementation for concurrent access
- **🔍 Type-Safe**: Compile-time type checking with generic protocols
- **🧪 Testing-Friendly**: Built-in mock container support
- **📊 Advanced Diagnostics**: Health monitoring, performance metrics, and memory management
- **📝 Integrated Logging**: Built-in integration with PrimerLogger

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
    _ = try await container.register(PaymentService.self)
        .asSingleton()
        .with { resolver in
            PaymentServiceImpl(
                apiClient: try await resolver.resolve(APIClient.self),
                keychain: try await resolver.resolve(KeychainService.self)
            )
        }
    
    // Register a transient repository
    _ = try await container.register(PaymentRepository.self)
        .asTransient()
        .with { resolver in
            PaymentRepositoryImpl(
                service: try await resolver.resolve(PaymentService.self)
            )
        }
    
    // Register with a name for multiple implementations
    _ = try await container.register(Logger.self)
        .named("console")
        .asSingleton()
        .with { _ in ConsoleLogger() }
}
```

### 3. Resolve Dependencies

The container uses manual resolution with async/sync support:

```swift
class PaymentViewModel: ObservableObject {
    private let paymentService: PaymentService
    private let repository: PaymentRepository
    private let logger: Logger
    
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        
        // Manual resolution with proper error handling
        self.paymentService = try await container.resolve(PaymentService.self)
        self.repository = try await container.resolve(PaymentRepository.self)
        self.logger = try await container.resolve(Logger.self, name: "console")
    }
    
    func processPayment() async {
        do {
            logger.info(message: "Processing payment...")
            let result = try await paymentService.process(amount: 100)
            // Handle success
        } catch {
            logger.error(message: "Payment failed: \(error)")
        }
    }
}
```

### 4. Synchronous Resolution for SwiftUI

For SwiftUI contexts that require synchronous access:

```swift
class PaymentUseCase {
    private let service: PaymentService
    private let logger: Logger
    
    init() throws {
        guard let container = DIContainer.currentSync else {
            throw ContainerError.containerUnavailable
        }
        
        // Synchronous resolution with timeout protection
        self.service = try container.resolveSync(PaymentService.self)
        self.logger = try container.resolveSync(Logger.self, name: "console")
    }
}
```

## Advanced Usage

### Factory Pattern

Use factories for objects that require parameters at creation time:

```swift
// Define a factory protocol
protocol PaymentMethodFactory: Factory {
    associatedtype Product = PaymentMethod
    associatedtype Params = PaymentMethodConfig
    
    func create(with params: PaymentMethodConfig) async throws -> PaymentMethod
}

class PaymentMethodFactoryImpl: PaymentMethodFactory {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func create(with config: PaymentMethodConfig) async throws -> PaymentMethod {
        switch config.type {
        case .card:
            return CardPaymentMethod(config: config, apiClient: apiClient)
        case .applePay:
            return ApplePayMethod(config: config, apiClient: apiClient)
        case .paypal:
            return PayPalMethod(config: config, apiClient: apiClient)
        }
    }
}

// Register the factory
guard let container = await DIContainer.current else { return }

_ = try await container.registerFactory(
    PaymentMethodFactoryImpl.self,
    policy: .singleton
) { resolver in
    let apiClient = try await resolver.resolve(APIClient.self)
    return PaymentMethodFactoryImpl(apiClient: apiClient)
}

// Use the factory
let factory = try await container.resolve(PaymentMethodFactoryImpl.self)
let paymentMethod = try await factory.create(with: config)
```

### Synchronous Factories

For factories that don't need async operations, implement `SynchronousFactory`:

```swift
protocol UserValidatorFactory: SynchronousFactory {
    associatedtype Product = UserValidator
    associatedtype Params = ValidationConfig
    
    func createSync(with params: ValidationConfig) throws -> UserValidator
}

class UserValidatorFactoryImpl: UserValidatorFactory {
    func createSync(with config: ValidationConfig) throws -> UserValidator {
        return UserValidator(rules: config.rules, strict: config.strictMode)
    }
}

// Register and use
_ = try await container.registerFactory(UserValidatorFactoryImpl())
let factory = try await container.resolve(UserValidatorFactoryImpl.self)
let validator = try factory.createSync(with: config)
```

### Scoped Containers

Create isolated dependency scopes for specific features:

```swift
class PaymentFlowScope: DependencyScope {
    let scopeId = "payment-flow"
    
    func setupContainer() async {
        guard let container = try? await getContainer() else { return }
        
        // Register flow-specific dependencies
        _ = try await container.register(PaymentFlowState.self)
            .asSingleton()
            .with { _ in PaymentFlowState() }
        
        _ = try await container.register(PaymentStepValidator.self)
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
let result = try await scope.withContainer { container in
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
        _ = try await mockContainer.register(PaymentService.self)
            .asSingleton()
            .with { _ in MockPaymentService() }
        
        _ = try await mockContainer.register(PrimerLogger.self)
            .asSingleton()
            .with { _ in MockLogger() }
    }
    
    func testPaymentProcessing() async throws {
        await DIContainer.withContainer(mockContainer) {
            // Create view model with mock dependencies
            let viewModel = try await PaymentViewModel()
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
_ = try await container.register(RequestLogger.self)
    .asTransient()
    .with { _ in RequestLogger() }
```

### Singleton
Creates one instance and reuses it throughout the app lifecycle:

```swift
_ = try await container.register(APIClient.self)
    .asSingleton()
    .with { _ in APIClient(baseURL: apiBaseURL) }
```

### Weak
Holds a weak reference, allowing the instance to be deallocated when no longer referenced:

```swift
_ = try await container.register(TemporaryCache.self)
    .asWeak()
    .with { _ in TemporaryCache() }
```

**Note**: Weak retention policy only works with class types (AnyObject). Using it with value types will result in an error.

## Error Handling

The container provides comprehensive error handling:

```swift
do {
    let service = try await container.resolve(PaymentService.self)
} catch ContainerError.dependencyNotRegistered(let key, let suggestions) {
    print("Dependency not found: \(key)")
    if !suggestions.isEmpty {
        print("Suggestions: \(suggestions.joined(separator: ", "))")
    }
} catch ContainerError.circularDependency(let key, let path) {
    let pathString = path.map { "\($0)" }.joined(separator: " → ")
    print("Circular dependency detected: \(pathString)")
} catch ContainerError.typeCastFailed(let key, let expected, let actual) {
    print("Type cast failed for \(key). Expected: \(expected), Actual: \(actual)")
} catch ContainerError.containerUnavailable {
    print("Container is not available")
} catch ContainerError.factoryFailed(let key, let error) {
    print("Factory failed for \(key): \(error)")
} catch ContainerError.weakUnsupported(let key) {
    print("Weak retention not supported for \(key)")
}
```

## Best Practices

### 1. **Register Early, Resolve Late**
Register all dependencies during app launch, resolve them when needed.

### 2. **Use Manual Resolution for ViewModels**
Manual resolution provides explicit control over dependency injection:

```swift
class ViewModel: ObservableObject {
    private let service: PaymentService
    
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        self.service = try await container.resolve(PaymentService.self)
    }
}
```

### 3. **Prefer Protocol Registration**
Register protocols instead of concrete types for better testability:

```swift
_ = try await container.register(PaymentServiceProtocol.self)
    .asSingleton()
    .with { _ in PaymentServiceImpl() }
```

### 4. **Use Scoped Containers for Feature Modules**
Isolate feature-specific dependencies in their own scopes.

### 5. **Keep Factory Parameters Simple**
Factory parameters should be simple value types or configuration objects.

### 6. **Handle Errors Gracefully**
Always handle potential resolution errors in your application logic.

## Architecture Integration

### MVVM with Clean Architecture

```swift
// Domain Layer
protocol PaymentUseCase {
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult
}

// Use Case Implementation
class ProcessPaymentUseCase: PaymentUseCase {
    private let repository: PaymentRepository
    private let validator: PaymentValidator
    
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        
        self.repository = try await container.resolve(PaymentRepository.self)
        self.validator = try await container.resolve(PaymentValidator.self)
    }
    
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult {
        try validator.validate(request)
        return try await repository.processPayment(request)
    }
}

// View Model
class PaymentViewModel: ObservableObject {
    private let useCase: PaymentUseCase
    @Published var state: PaymentState = .idle
    
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        
        self.useCase = try await container.resolve(PaymentUseCase.self)
    }
    
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

## Container Diagnostics & Health Monitoring

The DI container provides comprehensive diagnostics and health monitoring capabilities to help you debug and optimize your application's dependency injection.

### Container Diagnostics

Get detailed information about your container's state:

```swift
guard let container = await DIContainer.current as? Container else { return }

// Get diagnostics
let diagnostics = await container.getDiagnostics()
print(diagnostics)

// Print detailed report
diagnostics.printDetailedReport()
```

**Output Example:**
```
Container Diagnostics:
- Total Registrations: 5
- Singleton Instances: 3
- Weak References: 2 (active: 1)
- Memory Efficiency: 50.0%

Registered Types:
  - PaymentService
  - Logger(name: console)
  - APIClient
```

### Health Checks

Perform automated health checks to detect potential issues:

```swift
let healthReport = await container.performHealthCheck()
healthReport.printReport()

// Check specific status
switch healthReport.status {
case .healthy:
    print("✅ Container is healthy")
case .hasIssues:
    print("⚠️ Container has issues:")
    for issue in healthReport.issues {
        print("  - \(issue)")
    }
case .critical:
    print("🚨 Container has critical issues")
}
```

### Memory Management

Clean up dead weak references and optimize memory usage:

```swift
// Perform maintenance cleanup
await container.performMaintenanceCleanup()

// This will automatically:
// - Remove dead weak references
// - Log cleanup results
// - Optimize memory usage
```

### Performance Monitoring

Use `InstrumentedContainer` for detailed performance tracking:

```swift
// Create container with performance monitoring
let container = InstrumentedContainer(
    metrics: DefaultContainerMetrics()
)

// Register and use dependencies
_ = try await container.register(PaymentService.self).asSingleton().with { _ in PaymentServiceImpl() }
let service = try await container.resolve(PaymentService.self)

// Get performance metrics
await container.printPerformanceReport()
```

## Container Features

### Resolving All Dependencies

You can resolve all registered dependencies that conform to a specific protocol:

```swift
// Register multiple implementations
_ = try await container.register(PaymentProcessor.self)
    .named("stripe")
    .asSingleton()
    .with { _ in StripeProcessor() }

_ = try await container.register(PaymentProcessor.self)
    .named("paypal")
    .asSingleton()
    .with { _ in PayPalProcessor() }

// Resolve all processors
let allProcessors = await container.resolveAll(PaymentProcessor.self)
print("Found \(allProcessors.count) payment processors")
```

### Container Reset

Reset the container while preserving specific dependencies:

```swift
// Reset everything except core services
await container.reset(ignoreDependencies: [
    PrimerLogger.self,
    APIClient.self
])
```

### Temporary Container Context

Execute code with a temporary container:

```swift
let testContainer = Container()
// Set up test dependencies...

await DIContainer.withContainer(testContainer) {
    // Code runs with testContainer
    let service = try await testContainer.resolve(PaymentService.self)
    // ...
}
// Previous container is automatically restored
```

## SwiftUI Integration

Limited SwiftUI integration is available through the DIContainer extension:

```swift
@available(iOS 15.0, *)
extension DIContainer {
    @MainActor
    static func stateObject<T: ObservableObject>(
        _ type: T.Type = T.self,
        name: String? = nil,
        default fallback: @autoclosure @escaping () -> T
    ) -> StateObject<T> {
        // Attempts to resolve from container, falls back to default if resolution fails
    }
}

// Usage in SwiftUI views:
struct PaymentView: View {
    @StateObject private var viewModel = DIContainer.stateObject(
        PaymentViewModel.self,
        default: PaymentViewModel()
    )
    
    var body: some View {
        // View implementation
    }
}
```

## Performance Considerations

- **Actor-based Implementation**: Thread-safe without locks
- **Lazy Initialization**: Dependencies are created only when needed
- **Weak References**: Prevent memory leaks for temporary objects
- **Type Safety**: No runtime type checking overhead with TypeKey
- **Cached Resolution**: Singletons are cached for fast access
- **Synchronous Resolution**: Available with timeout protection for SwiftUI contexts

## Troubleshooting

### Common Issues

1. **"Dependency not registered" Error**
   - Ensure the dependency is registered before resolution
   - Check the type and name match exactly
   - Verify registration was awaited if it's async

2. **"Circular dependency detected" Error**
   - Review your dependency graph
   - Consider using factories or breaking the circular reference

3. **"Container unavailable" Error**
   - Make sure `DIContainer.setupMainContainer()` is called
   - For testing, use `DIContainer.withContainer()`

4. **"Weak retention not supported" Error**
   - Weak retention only works with class types (AnyObject)
   - Use `.singleton` or `.transient` for value types

5. **Synchronous resolution timeout**
   - Synchronous resolution has a 500ms timeout
   - Use async resolution when possible
   - Ensure dependencies can be resolved quickly

## Contributing

When contributing to the DI container:

1. Follow SOLID principles
2. Maintain async-first design
3. Add comprehensive tests
4. Update documentation
5. Ensure thread safety with actors

## Technical Details

### TypeKey System
The container uses a type-safe key system that combines ObjectIdentifier with optional names for distinguishing between multiple registrations of the same type.

### Retention Strategies
The container implements the Strategy pattern for retention policies:
- `TransientStrategy`: Creates new instances on each resolution
- `SingletonStrategy`: Maintains strong references for the container lifetime
- `WeakStrategy`: Maintains weak references allowing garbage collection

### Actor-based Concurrency
The Container class is an actor, ensuring thread-safe operations without traditional locking mechanisms.

## License

Copyright © 2025 Primer.io. All rights reserved.