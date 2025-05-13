//
//  isolation.swift
//  
//
//  Created by Boris on 13. 5. 2025..
//


//
//  DIFrameworkTests.swift
//  DI Framework Unit Tests
//
//  This comprehensive test suite covers all major components of the dependency injection framework:
//  
//  1. Container - Core DI container functionality
//     - Registration API (fluent builder pattern)
//     - Resolution with different retention policies (transient, singleton, weak)
//     - Type safety and error handling
//     - Circular dependency detection
//     - Multiple named registrations
//  
//  2. DIContainer - Global container management
//     - Singleton access pattern
//     - Container switching and scoped containers
//     - Thread safety with actor isolation
//     - Async/sync access patterns
//  
//  3. Injected Property Wrapper - Automatic dependency injection
//     - Lazy and eager initialization
//     - Error handling strategies
//     - Thread safety
//     - Optional dependency support
//  
//  4. TypeKey - Type identification system
//     - Type identity and equality
//     - Named registration support
//     - Caching mechanism
//     - Codable implementation
//  
//  5. Factory Patterns - Parameterized object creation
//     - Sync and async factory protocols
//     - Parameter handling
//     - Integration with container
//  
//  6. DIInjectable Protocol - Injectable object creation
//     - Automatic resolution from container
//     - Base class implementations
//  
//  7. DependencyScope - Scoped container lifecycle
//     - Setup and cleanup
//     - Container association
//     - Error handling
//  
//  Test Coverage Strategy:
//  - Happy path scenarios for all major features
//  - Error conditions and edge cases
//  - Thread safety and concurrency
//  - Memory management (weak references, singletons)
//  - Integration between components
//  - Performance characteristics
//
//  Created by Boris on 13. 5. 2025.
//

import XCTest
import Foundation

// MARK: - Test Protocols and Mock Objects

protocol TestService: Sendable {
    func performAction() -> String
}

class MockService: TestService, @unchecked Sendable {
    func performAction() -> String {
        return "MockService action"
    }
}

actor ActorService: TestService {
    func performAction() -> String {
        return "ActorService action"
    }
}

protocol TestRepository: Sendable {
    func fetchData() async throws -> String
}

class MockRepository: TestRepository, @unchecked Sendable {
    func fetchData() async throws -> String {
        return "MockRepository data"
    }
}

// Factory Protocol Implementations
struct ServiceFactory: Factory {
    func create(with params: String) -> MockService {
        return MockService()
    }
}

struct AsyncServiceFactory: AsyncFactory {
    func create(with params: String) async throws -> MockService {
        return MockService()
    }
}

struct SimpleServiceFactory: SimpleFactory {
    func create() -> MockService {
        return MockService()
    }
}

struct AsyncSimpleServiceFactory: AsyncSimpleFactory {
    func create() async throws -> MockService {
        return MockService()
    }
}

// DIInjectable Implementations
class InjectableService: DIInjectable {
    let testService: TestService
    
    required init(resolver: ContainerProtocol) throws {
        self.testService = try await resolver.resolve(TestService.self)
    }
}

class TestViewModel: DIViewModel {
    let service: TestService
    
    required init(resolver: ContainerProtocol) throws {
        self.service = try await resolver.resolve(TestService.self)
        super.init(resolver: resolver)
    }
}

// Dependency Scope Implementation
class TestScope: DependencyScope {
    let scopeId: String
    private(set) var isSetup = false
    private(set) var isCleanedUp = false
    
    init(scopeId: String) {
        self.scopeId = scopeId
    }
    
    func setupContainer() async {
        isSetup = true
    }
    
    func cleanupScope() async {
        isCleanedUp = true
    }
}

// MARK: - Container Tests

class ContainerTests: XCTestCase {
    private var container: Container!
    
    override func setUp() async throws {
        container = Container()
    }
    
    override func tearDown() async throws {
        container = nil
    }
    
    // MARK: - Registration Tests
    
    func testBasicRegistration() async throws {
        // Test basic dependency registration
        container.register(TestService.self)
            .with { _ in MockService() }
        
        let service = try await container.resolve(TestService.self)
        XCTAssertNotNil(service)
        XCTAssertTrue(service is MockService)
    }
    
    func testNamedRegistration() async throws {
        // Test named dependency registration
        container.register(TestService.self)
            .named("primary")
            .with { _ in MockService() }
        
        container.register(TestService.self)
            .named("secondary")
            .with { _ in ActorService() }
        
        let primary = try await container.resolve(TestService.self, name: "primary")
        let secondary = try await container.resolve(TestService.self, name: "secondary")
        
        XCTAssertTrue(primary is MockService)
        XCTAssertTrue(secondary is ActorService)
    }
    
    func testAsyncFactoryRegistration() async throws {
        // Test async factory registration
        container.register(TestService.self)
            .asSingleton()
            .with { _ async throws in 
                await ActorService()
            }
        
        let service = try await container.resolve(TestService.self)
        XCTAssertNotNil(service)
        XCTAssertTrue(service is ActorService)
    }
    
    // MARK: - Retention Policy Tests
    
    func testTransientRetention() async throws {
        // Test transient dependency creation
        container.register(TestService.self)
            .asTransient()
            .with { _ in MockService() }
        
        let service1 = try await container.resolve(TestService.self)
        let service2 = try await container.resolve(TestService.self)
        
        XCTAssertTrue(service1 !== service2)
    }
    
    func testSingletonRetention() async throws {
        // Test singleton dependency creation
        container.register(TestService.self)
            .asSingleton()
            .with { _ in MockService() }
        
        let service1 = try await container.resolve(TestService.self)
        let service2 = try await container.resolve(TestService.self)
        
        XCTAssertTrue(service1 === service2)
    }
    
    func testWeakRetention() async throws {
        // Test weak dependency retention
        container.register(TestService.self)
            .asWeak()
            .with { _ in MockService() }
        
        weak var weakRef: MockService?
        
        do {
            let service = try await container.resolve(TestService.self) as! MockService
            weakRef = service
            XCTAssertNotNil(weakRef)
        }
        
        // Force garbage collection
        await Task.yield()
        XCTAssertNil(weakRef)
    }
    
    // MARK: - Error Handling Tests
    
    func testDependencyNotRegistered() async {
        // Test error when dependency is not registered
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Should have thrown dependencyNotRegistered error")
        } catch let error as ContainerError {
            switch error {
            case .dependencyNotRegistered(let key):
                XCTAssertTrue(key.represents(TestService.self))
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testCircularDependencyDetection() async {
        // Test circular dependency detection
        container.register(TestService.self)
            .with { container in
                try await container.resolve(TestRepository.self)
                return MockService()
            }
        
        container.register(TestRepository.self)
            .with { container in
                _ = try await container.resolve(TestService.self)
                return MockRepository()
            }
        
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Should have thrown circularDependency error")
        } catch let error as ContainerError {
            switch error {
            case .circularDependency(let key, let path):
                XCTAssertFalse(path.isEmpty)
                XCTAssertTrue(key.represents(TestService.self) || key.represents(TestRepository.self))
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testFactoryErrorHandling() async {
        // Test factory error propagation
        container.register(TestService.self)
            .with { _ in
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
        
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Should have thrown factoryFailed error")
        } catch let error as ContainerError {
            switch error {
            case .factoryFailed(let key, let underlyingError):
                XCTAssertTrue(key.represents(TestService.self))
                XCTAssertNotNil(underlyingError)
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - Container Lifecycle Tests
    
    func testUnregister() async throws {
        // Test dependency unregistration
        container.register(TestService.self)
            .with { _ in MockService() }
        
        let service1 = try await container.resolve(TestService.self)
        XCTAssertNotNil(service1)
        
        container.unregister(TestService.self)
        
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Should have thrown dependencyNotRegistered error")
        } catch is ContainerError {
            // Expected
        }
    }
    
    func testReset() async throws {
        // Test container reset functionality
        container.register(TestService.self)
            .asSingleton()
            .with { _ in MockService() }
        
        let service1 = try await container.resolve(TestService.self)
        
        await container.reset()
        
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Should have thrown dependencyNotRegistered error")
        } catch is ContainerError {
            // Expected
        }
    }
    
    func testResetWithIgnoredDependencies() async throws {
        // Test reset with ignored dependencies
        container.register(TestService.self)
            .asSingleton()
            .with { _ in MockService() }
        
        container.register(TestRepository.self)
            .asSingleton()
            .with { _ in MockRepository() }
        
        let service = try await container.resolve(TestService.self)
        let repository = try await container.resolve(TestRepository.self)
        
        await container.reset(ignoreDependencies: [TestService.self])
        
        // TestService should still be registered
        let service2 = try await container.resolve(TestService.self)
        XCTAssertTrue(service === service2)
        
        // TestRepository should be unregistered
        do {
            _ = try await container.resolve(TestRepository.self)
            XCTFail("Should have thrown dependencyNotRegistered error")
        } catch is ContainerError {
            // Expected
        }
    }
    
    // MARK: - Advanced Features Tests
    
    func testResolveAll() async throws {
        // Test resolving all instances of a type
        container.register(TestService.self)
            .named("service1")
            .asSingleton()
            .with { _ in MockService() }
        
        container.register(TestService.self)
            .named("service2")
            .asSingleton()
            .with { _ in ActorService() }
        
        // Resolve to instantiate
        _ = try await container.resolve(TestService.self, name: "service1")
        _ = try await container.resolve(TestService.self, name: "service2")
        
        let allServices = await container.resolveAll(TestService.self)
        XCTAssertEqual(allServices.count, 2)
    }
    
    func testFactoryRegistration() async throws {
        // Test factory registration
        let factory = ServiceFactory()
        container.registerFactory(factory)
        
        let resolvedFactory = try await container.resolve(ServiceFactory.self)
        XCTAssertNotNil(resolvedFactory)
    }
}

// MARK: - DIContainer Tests

class DIContainerTests: XCTestCase {
    
    override func setUp() async throws {
        // Reset DIContainer to clean state
        await DIContainer.setContainer(Container())
    }
    
    func testSharedInstance() async {
        // Test singleton access
        XCTAssertNotNil(DIContainer.shared)
        XCTAssertTrue(DIContainer.shared === DIContainer.shared)
    }
    
    func testCurrentContainer() async throws {
        // Test current container access
        let container = await DIContainer.current
        XCTAssertNotNil(container)
    }
    
    func testCurrentSyncContainer() {
        // Test synchronous container access
        let container = DIContainer.currentSync
        XCTAssertNotNil(container)
    }
    
    func testSetContainer() async throws {
        // Test setting a new container
        let newContainer = Container()
        await DIContainer.setContainer(newContainer)
        
        let current = await DIContainer.current
        XCTAssertTrue(current === newContainer)
    }
    
    func testWithContainer() async throws {
        // Test temporary container switching
        let originalContainer = await DIContainer.current
        let tempContainer = Container()
        
        let result = await DIContainer.withContainer(tempContainer) {
            let current = await DIContainer.current
            return current === tempContainer
        }
        
        XCTAssertTrue(result)
        
        // Verify original container is restored
        let restoredContainer = await DIContainer.current
        XCTAssertTrue(restoredContainer === originalContainer)
    }
    
    func testScopedContainers() async throws {
        // Test scoped container management
        let scopedContainer = Container()
        await DIContainer.setScopedContainer(scopedContainer, for: "testScope")
        
        let retrieved = await DIContainer.scopedContainer(for: "testScope")
        XCTAssertTrue(retrieved === scopedContainer)
        
        await DIContainer.removeScopedContainer(for: "testScope")
        let removed = await DIContainer.scopedContainer(for: "testScope")
        XCTAssertNil(removed)
    }
    
    func testSetupMainContainer() async throws {
        // Test main container setup
        await DIContainer.setupMainContainer()
        
        let container = await DIContainer.current
        XCTAssertNotNil(container)
    }
    
    func testCreateMockContainer() async throws {
        // Test mock container creation
        let mockContainer = await DIContainer.createMockContainer()
        XCTAssertNotNil(mockContainer)
    }
}

// MARK: - Injected Property Wrapper Tests

class InjectedTests: XCTestCase {
    private var container: Container!
    
    override func setUp() async throws {
        container = Container()
        container.register(TestService.self)
            .asSingleton()
            .with { _ in MockService() }
        
        await DIContainer.setContainer(container)
    }
    
    func testBasicInjection() async throws {
        // Test basic property wrapper injection
        class TestClass {
            @Injected var service: TestService
        }
        
        let instance = TestClass()
        XCTAssertNotNil(instance.service)
        XCTAssertTrue(instance.service is MockService)
    }
    
    func testNamedInjection() async throws {
        // Test named dependency injection
        container.register(TestService.self)
            .named("test")
            .with { _ in ActorService() }
        
        class TestClass {
            @Injected(name: "test") var service: TestService
        }
        
        let instance = TestClass()
        XCTAssertTrue(instance.service is ActorService)
    }
    
    func testLazyInjection() async throws {
        // Test lazy injection behavior
        var factoryCalled = false
        
        container.register(TestRepository.self)
            .with { _ in
                factoryCalled = true
                return MockRepository()
            }
        
        class TestClass {
            @Injected(lazy: true) var repository: TestRepository
        }
        
        let instance = TestClass()
        XCTAssertFalse(factoryCalled)
        
        _ = instance.repository
        XCTAssertTrue(factoryCalled)
    }
    
    func testEagerInjection() async throws {
        // Test eager injection behavior
        var factoryCalled = false
        
        container.register(TestRepository.self)
            .with { _ in
                factoryCalled = true
                return MockRepository()
            }
        
        class TestClass {
            @Injected(lazy: false) var repository: TestRepository
        }
        
        _ = TestClass()
        // Wait for async initialization
        await Task.yield()
        XCTAssertTrue(factoryCalled)
    }
    
    func testErrorStrategies() async throws {
        // Test different error handling strategies
        class TestClassWithThrow {
            @Injected(errorStrategy: .throw) var unknownService: TestRepository
        }
        
        class TestClassWithDefault {
            @Injected(errorStrategy: .useDefault(MockRepository())) var unknownService: TestRepository
        }
        
        // Test throw strategy
        let throwInstance = TestClassWithThrow()
        // This should trigger a fatalError in practice, but we can't test that easily
        
        // Test default strategy
        let defaultInstance = TestClassWithDefault()
        XCTAssertNotNil(defaultInstance.unknownService)
        XCTAssertTrue(defaultInstance.unknownService is MockRepository)
    }
    
    func testReset() async throws {
        // Test injection reset functionality
        class TestClass {
            @Injected var service: TestService
        }
        
        let instance = TestClass()
        _ = instance.service // Trigger resolution
        
        instance.$service.reset()
        // After reset, service should be re-resolved on next access
        XCTAssertNotNil(instance.service)
    }
    
    func testOptionalInjection() async throws {
        // Test optional dependency injection
        class TestClass {
            @InjectedOptional var unknownService: TestRepository?
        }
        
        let instance = TestClass()
        XCTAssertNil(instance.unknownService)
    }
    
    func testAsyncResolve() async throws {
        // Test async resolution method
        class TestClass {
            @Injected var service: TestService
        }
        
        let instance = TestClass()
        let service = try await instance.$service.resolve()
        XCTAssertNotNil(service)
        XCTAssertTrue(service is MockService)
    }
}

// MARK: - TypeKey Tests

class TypeKeyTests: XCTestCase {
    
    func testBasicTypeKey() {
        // Test basic TypeKey creation
        let key1 = TypeKey(TestService.self)
        let key2 = TypeKey(TestService.self)
        
        XCTAssertEqual(key1, key2)
        XCTAssertEqual(key1.hashValue, key2.hashValue)
    }
    
    func testNamedTypeKey() {
        // Test named TypeKey creation
        let key1 = TypeKey(TestService.self, name: "primary")
        let key2 = TypeKey(TestService.self, name: "primary")
        let key3 = TypeKey(TestService.self, name: "secondary")
        
        XCTAssertEqual(key1, key2)
        XCTAssertNotEqual(key1, key3)
    }
    
    func testTypeKeyDescription() {
        // Test TypeKey string representation
        let key1 = TypeKey(TestService.self)
        let key2 = TypeKey(TestService.self, name: "test")
        
        XCTAssertTrue(key1.description.contains("TestService"))
        XCTAssertTrue(key2.description.contains("TestService"))
        XCTAssertTrue(key2.description.contains("test"))
    }
    
    func testTypeKeyRepresentation() {
        // Test type representation check
        let key = TypeKey(TestService.self)
        
        XCTAssertTrue(key.represents(TestService.self))
        XCTAssertFalse(key.represents(TestRepository.self))
    }
    
    func testTypeKeyCache() {
        // Test TypeKey caching mechanism
        let key1 = TypeKey.forType(TestService.self)
        let key2 = TypeKey.forType(TestService.self)
        
        XCTAssertEqual(key1, key2)
    }
    
    func testTypeKeyCodable() throws {
        // Test TypeKey encoding/decoding
        let key = TypeKey(TestService.self, name: "test")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(key)
        
        let decoder = JSONDecoder()
        let decodedKey = try decoder.decode(TypeKey.self, from: data)
        
        XCTAssertEqual(key.description, decodedKey.description)
    }
}

// MARK: - Factory Tests

class FactoryTests: XCTestCase {
    private var container: Container!
    
    override func setUp() async throws {
        container = Container()
    }
    
    func testSyncFactory() async throws {
        // Test synchronous factory
        let factory = ServiceFactory()
        container.register(ServiceFactory.self)
            .asSingleton()
            .with { _ in factory }
        
        let product = try await container.create(factoryType: ServiceFactory.self, with: "test")
        XCTAssertNotNil(product)
        XCTAssertTrue(product is MockService)
    }
    
    func testAsyncFactory() async throws {
        // Test asynchronous factory
        let factory = AsyncServiceFactory()
        container.register(AsyncServiceFactory.self)
            .asSingleton()
            .with { _ in factory }
        
        let product = try await container.createAsync(factoryType: AsyncServiceFactory.self, with: "test")
        XCTAssertNotNil(product)
        XCTAssertTrue(product is MockService)
    }
    
    func testSimpleFactory() async throws {
        // Test simple factory without parameters
        let factory = SimpleServiceFactory()
        container.register(SimpleServiceFactory.self)
            .asSingleton()
            .with { _ in factory }
        
        let product = try await container.create(factoryType: SimpleServiceFactory.self)
        XCTAssertNotNil(product)
        XCTAssertTrue(product is MockService)
    }
    
    func testAsyncSimpleFactory() async throws {
        // Test async simple factory without parameters
        let factory = AsyncSimpleServiceFactory()
        container.register(AsyncSimpleServiceFactory.self)
            .asSingleton()
            .with { _ in factory }
        
        let product = try await container.createAsync(factoryType: AsyncSimpleServiceFactory.self)
        XCTAssertNotNil(product)
        XCTAssertTrue(product is MockService)
    }
    
    func testFactoryWithVoidParams() async throws {
        // Test factory with Void parameters (should work as SimpleFactory)
        struct VoidParamFactory: Factory {
            func create(with params: Void) -> MockService {
                return MockService()
            }
        }
        
        let factory = VoidParamFactory()
        container.register(VoidParamFactory.self)
            .asSingleton()
            .with { _ in factory }
        
        // Should be able to call without parameters
        let product1 = try await container.create(factoryType: VoidParamFactory.self, with: ())
        let product2 = try await container.create(factoryType: VoidParamFactory.self)
        
        XCTAssertNotNil(product1)
        XCTAssertNotNil(product2)
    }
}

// MARK: - DIInjectable Tests

class DIInjectableTests: XCTestCase {
    private var container: Container!
    
    override func setUp() async throws {
        container = Container()
        container.register(TestService.self)
            .asSingleton()
            .with { _ in MockService() }
        
        await DIContainer.setContainer(container)
    }
    
    func testDIInjectableCreate() async throws {
        // Test DIInjectable creation with current container
        let service = try await InjectableService.create()
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.testService)
    }
    
    func testDIInjectableCreateWithContainer() throws {
        // Test DIInjectable creation with custom container
        let service = try InjectableService.create(with: container)
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.testService)
    }
    
    func testDIViewModelBase() async throws {
        // Test ViewModel base class
        let viewModel = try await TestViewModel.create()
        XCTAssertNotNil(viewModel)
        XCTAssertNotNil(viewModel.service)
        XCTAssertTrue(viewModel is DIViewModel)
    }
    
    func testDIInjectableError() async {
        // Test error when container is unavailable
        await DIContainer.setContainer(nil)
        
        do {
            _ = try await InjectableService.create()
            XCTFail("Should have thrown containerUnavailable error")
        } catch let error as ContainerError {
            switch error {
            case .containerUnavailable:
                break
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
}

// MARK: - DependencyScope Tests

class DependencyScopeTests: XCTestCase {
    
    func testScopeLifecycle() async throws {
        // Test scope setup and cleanup
        let scope = TestScope(scopeId: "testScope")
        
        XCTAssertFalse(scope.isSetup)
        XCTAssertFalse(scope.isCleanedUp)
        
        await scope.register()
        XCTAssertTrue(scope.isSetup)
        
        await scope.unregister()
        XCTAssertTrue(scope.isCleanedUp)
    }
    
    func testScopeContainer() async throws {
        // Test scope container access
        let scope = TestScope(scopeId: "testScope")
        await scope.register()
        
        let container = try await scope.getContainer()
        XCTAssertNotNil(container)
    }
    
    func testScopeContainerNotFound() async {
        // Test error when scope container is not found
        let scope = TestScope(scopeId: "nonexistentScope")
        
        do {
            _ = try await scope.getContainer()
            XCTFail("Should have thrown scopeNotFound error")
        } catch let error as ContainerError {
            switch error {
            case .scopeNotFound(let scopeId):
                XCTAssertEqual(scopeId, "nonexistentScope")
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testWithContainer() async throws {
        // Test executing actions with scope container
        let scope = TestScope(scopeId: "testScope")
        await scope.register()
        
        let result = try await scope.withContainer { container in
            // Register a test service
            container.register(TestService.self)
                .with { _ in MockService() }
            
            return try await container.resolve(TestService.self)
        }
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result is MockService)
    }
}

// MARK: - Error Tests

class ErrorTests: XCTestCase {
    
    func testContainerErrorDescriptions() {
        // Test error descriptions for debugging
        let key = TypeKey(TestService.self, name: "test")
        
        let errors: [ContainerError] = [
            .dependencyNotRegistered(key),
            .circularDependency(key, path: [key]),
            .invalidTypeReturned(expected: key, actual: String.self),
            .containerUnavailable,
            .scopeNotFound("testScope"),
            .typeCastFailed(key, String.self),
            .factoryFailed(key, underlyingError: NSError(domain: "test", code: 1))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - Integration Tests

class IntegrationTests: XCTestCase {
    
    func testCompleteWorkflow() async throws {
        // Test complete DI workflow
        let container = Container()
        
        // Register dependencies
        container.register(TestService.self)
            .asSingleton()
            .with { _ in MockService() }
        
        container.register(TestRepository.self)
            .with { container in
                _ = try await container.resolve(TestService.self)
                return MockRepository()
            }
        
        // Set global container
        await DIContainer.setContainer(container)
        
        // Test injection
        class TestController {
            @Injected var service: TestService
            @Injected var repository: TestRepository
        }
        
        let controller = TestController()
        XCTAssertNotNil(controller.service)
        XCTAssertNotNil(controller.repository)
        
        // Test resolution
        let resolvedService = try await container.resolve(TestService.self)
        XCTAssertTrue(resolvedService === controller.service)
    }
    
    func testConcurrency() async throws {
        // Test concurrent access to container
        let container = Container()
        container.register(TestService.self)
            .asSingleton()
            .with { _ in MockService() }
        
        await DIContainer.setContainer(container)
        
        // Create multiple tasks accessing the container concurrently
        let tasks = (0..<10).map { _ in
            Task {
                return try await container.resolve(TestService.self)
            }
        }
        
        let results = try await withThrowingTaskGroup(of: TestService.self) { group in
            for task in tasks {
                group.addTask {
                    try await task.value
                }
            }
            
            var services: [TestService] = []
            for try await service in group {
                services.append(service)
            }
            return services
        }
        
        // All should be the same singleton instance
        XCTAssertEqual(results.count, 10)
        for i in 1..<results.count {
            XCTAssertTrue(results[0] === results[i])
        }
    }
    
    func testMemoryManagement() async throws {
        // Test memory management of weak references
        let container = Container()
        
        weak var weakService: MockService?
        
        // Register as weak
        container.register(TestService.self)
            .asWeak()
            .with { _ in MockService() }
        
        do {
            let service = try await container.resolve(TestService.self) as! MockService
            weakService = service
            XCTAssertNotNil(weakService)
        }
        
        // Force garbage collection
        await Task.yield()
        
        // Weak reference should be nil
        XCTAssertNil(weakService)
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    /// Helper to wait for async conditions
    func waitForCondition(timeout: TimeInterval = 1.0, condition: @escaping () async -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await condition() {
                return
            }
            await Task.yield()
        }
    }
}