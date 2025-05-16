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

### 3. Inject Dependencies

#### Using Property Wrapper

```swift
class PaymentViewModel: ObservableObject {
    @Injected private var paymentService: PaymentService
    @Injected private var repository: PaymentRepository
    @Injected(name: "console") private var logger: Logger
    @InjectedOptional private var analytics: AnalyticsService?
    
    func processPayment() async {
        do {
            let service = try await $paymentService.resolve()
            let repo = try await $repository.resolve()
            let log = try await $logger.resolve()
            
            log.info(message: "Processing payment...")
            let result = try await service.process(amount: 100)
            
            if let analytics = await $analytics.resolve() {
                analytics.track("payment_success")
            }
        } catch {
            print("Payment failed: \(error)")
        }
    }
}
```

#### Manual Resolution  (Recommended)

```swift
class PaymentUseCase {
    private let service: PaymentService
    private let logger: PrimerLogger
    
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        
        self.service = try await container.resolve(PaymentService.self)
        self.logger = try await container.resolve(PrimerLogger.self)
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
    func create(with config: PaymentMethodConfig) async throws -> PaymentMethod {
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
_ = try await container.registerFactory(PaymentMethodFactoryImpl())

// Use the factory
guard let container = await DIContainer.current else { return }
let factory = try await container.resolve(PaymentMethodFactory.self)
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
let factory = try await container.resolve(UserValidatorFactory.self)
let validator = try await factory.create(with: config)
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
} catch ContainerError.dependencyNotRegistered(let key) {
    print("Dependency not found: \(key)")
} catch ContainerError.circularDependency(let key, let path) {
    print("Circular dependency detected: \(path)")
} catch ContainerError.typeCastFailed(let key, let type) {
    print("Type cast failed for \(key) to \(type)")
} catch ContainerError.containerUnavailable {
    print("Container is not available")
} catch ContainerError.factoryFailed(let key, let error) {
    print("Factory failed for \(key): \(error)")
} catch ContainerError.weakUnsupported(let key) {
    print("Weak retention not supported for \(key)")
}
```

## Property Wrapper Options

### Available Property Wrappers

```swift
class SomeService {
    // Standard injection - throws error on resolution failure
    @Injected var requiredService: PaymentService
    
    // Async injection (identical to @Injected)
    @InjectedAsync var asyncService: PaymentService
    
    // Optional dependency (never throws)
    @InjectedOptional var optionalService: AnalyticsService?
    
    // Named dependency
    @Injected(name: "console") var namedLogger: Logger
}
```

### Usage Pattern

All property wrappers require async resolution:

```swift
class ViewModel {
    @Injected private var service: PaymentService
    @InjectedOptional private var analytics: AnalyticsService?
    
    func performAction() async {
        do {
            // Resolve required dependency
            let svc = try await $service.resolve()
            let result = try await svc.process()
            
            // Resolve optional dependency
            if let analytics = await $analytics.resolve() {
                analytics.track("action_performed")
            }
        } catch {
            print("Resolution failed: \(error)")
        }
    }
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
_ = try await container.register(PaymentServiceProtocol.self)
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
class ProcessPaymentUseCase: PaymentUseCase {
    @Injected private var repository: PaymentRepository
    @Injected private var validator: PaymentValidator
    
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult {
        let repo = try await $repository.resolve()
        let val = try await $validator.resolve()
        
        try val.validate(request)
        return try await repo.processPayment(request)
    }
}

// View Model
class PaymentViewModel: ObservableObject {
    @Injected private var useCase: PaymentUseCase
    @Published var state: PaymentState = .idle
    
    func processPayment(_ request: PaymentRequest) async {
        state = .processing
        
        do {
            let uc = try await $useCase.resolve()
            let result = try await uc.processPayment(request)
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
let container = Container()

// Register some dependencies
_ = try await container.register(PaymentService.self).asSingleton().with { _ in PaymentServiceImpl() }
_ = try await container.register(Logger.self).asWeak().with { _ in ConsoleLogger() }

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

**Health Check Output:**
```
🔍 Container Health Report
Status: hasIssues

⚠️ Issues Found:
  - Low weak reference efficiency: 50.0%
  - orphanedRegistrations(3)

💡 Recommendations:
  - Consider calling performMaintenanceCleanup() more frequently
  - Remove unused registrations to improve performance

📊 Diagnostics:
Container Diagnostics:
- Total Registrations: 8
- Singleton Instances: 5
- Weak References: 4 (active: 2)
- Memory Efficiency: 50.0%
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
    metrics: DefaultContainerMetrics(),
    logger: { message in print("Container: \(message)") }
)

// Register and use dependencies
_ = try await container.register(PaymentService.self).asSingleton().with { _ in PaymentServiceImpl() }
let service = try await container.resolve(PaymentService.self)

// Get performance metrics
await container.printPerformanceReport()
```

**Performance Report Output:**
```
Container Performance Metrics:
- Total Resolutions: 150
- Average Resolution Time: 0.45ms
- Cache Hit Rate: 85.3%
- Memory Usage: ~2048 bytes

Slowest Resolutions:
  - PaymentService: 2.1ms
  - DatabaseManager: 1.8ms
  - NetworkClient: 1.2ms
```

### Diagnostic Integration in App Lifecycle

Integrate diagnostics into your app's lifecycle for continuous monitoring:

```swift
class AppDelegate: UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        Task {
            // Perform cleanup when app goes to background
            if let container = await DIContainer.current as? Container {
                await container.performMaintenanceCleanup()
            }
        }
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Task {
            // Emergency cleanup on memory warning
            if let container = await DIContainer.current as? Container {
                await container.performMaintenanceCleanup()
                
                let healthReport = await container.performHealthCheck()
                if healthReport.status == .critical {
                    // Log critical issues for debugging
                    print("🚨 Container health critical after memory warning")
                    healthReport.printReport()
                }
            }
        }
    }
}
```

### Debug Logging Integration

Enable detailed logging for troubleshooting:

```swift
let container = Container { message in
    #if DEBUG
    print("📦 Container: \(message)")
    #endif
}

// Or with PrimerLogger integration
let container = Container { message in
    PrimerLogging.shared.logger.debug(message: "Container: \(message)")
}
```

### Advanced Diagnostics for Development

Create development-only diagnostic tools:

```swift
#if DEBUG
extension Container {
    func printDetailedStatus() async {
        let diagnostics = getDiagnostics()
        let healthReport = await performHealthCheck()
        
        print("""
        
        🔍 CONTAINER STATUS REPORT
        =========================
        \(diagnostics.description)
        
        Health Status: \(healthReport.status)
        Issues: \(healthReport.issues.count)
        Recommendations: \(healthReport.recommendations.count)
        
        """)
        
        if let instrumented = self as? InstrumentedContainer {
            await instrumented.printPerformanceReport()
        }
    }
}
#endif

// Usage in development
#if DEBUG
await container.printDetailedStatus()
#endif
```

### Monitoring Best Practices

1. **Regular Health Checks**: Check container health during app launch and periodically
2. **Memory Cleanup**: Call `performMaintenanceCleanup()` during low-memory warnings
3. **Performance Monitoring**: Use `InstrumentedContainer` in debug builds
4. **Diagnostic Logging**: Enable container logging for development and testing

```swift
// Best practice setup
func setupContainer() async {
    #if DEBUG
    let container = InstrumentedContainer(
        metrics: DefaultContainerMetrics(),
        logger: { PrimerLogging.shared.logger.debug(message: $0) }
    )
    #else
    let container = Container()
    #endif
    
    // Register dependencies...
    
    // Initial health check
    let healthReport = await container.performHealthCheck()
    if healthReport.status != .healthy {
        healthReport.printReport()
    }
    
    await DIContainer.setContainer(container)
}
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

## Performance Considerations

- **Actor-based Implementation**: Thread-safe without locks
- **Lazy Initialization**: Dependencies are created only when needed
- **Weak References**: Prevent memory leaks for temporary objects
- **Type Safety**: No runtime type checking overhead with TypeKey
- **Cached Resolution**: Singletons are cached for fast access

## Migration from Other DI Frameworks

### From Swinject

```swift
// Swinject
container.register(PaymentService.self) { r in
    PaymentServiceImpl(apiClient: r.resolve(APIClient.self)!)
}

// Primer DI
_ = try await container.register(PaymentService.self)
    .asSingleton()
    .with { resolver in
        PaymentServiceImpl(apiClient: try await resolver.resolve(APIClient.self))
    }
```

### From Resolver

```swift
// Both frameworks use similar property wrapper syntax
@Injected var paymentService: PaymentService

// But Primer DI requires async resolution:
let service = try await $paymentService.resolve()
```

## Logging Integration

The container integrates with PrimerLogger for debugging and monitoring:

```swift
// Logger is automatically registered during setup
let logger = try await container.resolve(PrimerLogger.self)
logger.debug(message: "Container operation completed")
```

Internal container operations are logged when a logger is configured:

```swift
let container = Container { message in
    print("Container: \(message)")
}
```

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

5. **Property wrapper resolution issues**
   - Remember to use `try await $property.resolve()` syntax
   - Property wrappers cannot be accessed synchronously

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
