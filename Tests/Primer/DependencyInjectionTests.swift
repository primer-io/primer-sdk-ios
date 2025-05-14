////
////  DIFrameworkTests.swift
////  DI Framework Unit Tests
////
////  This comprehensive test suite covers all major components of the dependency injection framework:
////
////  1. Container - Core DI container functionality
////     - Registration API (fluent builder pattern)
////     - Resolution with different retention policies (transient, singleton, weak)
////     - Type safety and error handling
////     - Circular dependency detection
////     - Multiple named registrations
////
////  2. DIContainer - Global container management
////     - Singleton access pattern
////     - Container switching and scoped containers
////     - Thread safety with actor isolation
////     - Async/sync access patterns
////
////  3. Injected Property Wrapper - Automatic dependency injection
////     - Lazy and eager initialization
////     - Error handling strategies
////     - Thread safety
////     - Optional dependency support
////
////  4. TypeKey - Type identification system
////     - Type identity and equality
////     - Named registration support
////     - Caching mechanism
////     - Codable implementation
////
////  5. Factory Patterns - Parameterized object creation
////     - Sync and async factory protocols
////     - Parameter handling
////     - Integration with container
////
////  6. DIInjectable Protocol - Injectable object creation
////     - Automatic resolution from container
////     - Base class implementations
////
////  7. DependencyScope - Scoped container lifecycle
////     - Setup and cleanup
////     - Container association
////     - Error handling
////
////  Test Coverage Strategy:
////  - Happy path scenarios for all major features
////  - Error conditions and edge cases
////  - Thread safety and concurrency
////  - Memory management (weak references, singletons)
////  - Integration between components
////  - Performance characteristics
////
////  Created by Boris on 13. 5. 2025.
////
//
//import XCTest
//import Foundation
//@testable import PrimerSDK
//
//// MARK: - Test Protocols and Mock Objects
//
//protocol TestService: Sendable {
//    func performAction() async -> String
//}
//
//class MockService: TestService, @unchecked Sendable {
//    func performAction() async -> String {
//        return "MockService action"
//    }
//}
//
//actor ActorService: TestService {
//    func performAction() async -> String {
//        return "ActorService action"
//    }
//}
//
//protocol TestRepository: Sendable {
//    func fetchData() async throws -> String
//}
//
//class MockRepository: TestRepository, @unchecked Sendable {
//    func fetchData() async throws -> String {
//        return "MockRepository data"
//    }
//}
//
//// Factory Protocol Implementations
//struct ServiceFactory: Factory {
//    func create(with params: String) -> MockService {
//        return MockService()
//    }
//}
//
//struct AsyncServiceFactory: AsyncFactory {
//    func create(with params: String) async throws -> MockService {
//        return MockService()
//    }
//}
//
//struct SimpleServiceFactory: SimpleFactory {
//    func create() -> MockService {
//        return MockService()
//    }
//}
//
//struct AsyncSimpleServiceFactory: AsyncSimpleFactory {
//    func create() async throws -> MockService {
//        return MockService()
//    }
//}
//
//// DIInjectable Implementations
//class InjectableService: DIInjectable {
//    required init(resolver: any PrimerSDK.ContainerProtocol) throws {
//        <#code#>
//    }
//    
//    let testService: TestService
//
//    required init(resolver: ContainerProtocol) async throws {
//        self.testService = try await resolver.resolve(TestService.self, name: nil)
//    }
//}
//
//class TestViewModel: DIViewModel {
//    let service: TestService
//
//    required init(resolver: ContainerProtocol) async throws {
//        self.service = try await resolver.resolve(TestService.self, name: nil)
//        try await super.init(resolver: resolver)
//    }
//}
//
//// Custom DIViewModel base for testing
//class CustomDIViewModel: DIInjectable {
//    required init(resolver: ContainerProtocol) async throws {
//        // Default empty implementation
//    }
//}
//
//// Dependency Scope Implementation
//class TestScope: DependencyScope {
//    let scopeId: String
//    private(set) var isSetup = false
//    private(set) var isCleanedUp = false
//
//    init(scopeId: String) {
//        self.scopeId = scopeId
//    }
//
//    func setupContainer() async {
//        isSetup = true
//    }
//
//    func cleanupScope() async {
//        isCleanedUp = true
//    }
//}
//
//// MARK: - Container Tests
//
//class ContainerTests: XCTestCase {
//    private var container: Container!
//
//    override func setUp() async throws {
//        container = Container()
//    }
//
//    override func tearDown() async throws {
//        container = nil
//    }
//
//    // MARK: - Registration Tests
//
//    func testBasicRegistration() async throws {
//        // Test basic dependency registration
//        _ = container.register(TestService.self)
//            .with { _ in MockService() }
//
//        let service = try await container.resolve(TestService.self, name: nil)
//        XCTAssertNotNil(service)
//        XCTAssertTrue(service is MockService)
//    }
//
//    func testNamedRegistration() async throws {
//        // Test named dependency registration
//        _ = container.register(TestService.self)
//            .named("primary")
//            .with { _ in MockService() }
//
//        _ = container.register(TestService.self)
//            .named("secondary")
//            .with { _ in ActorService() }
//
//        let primary = try await container.resolve(TestService.self, name: "primary")
//        let secondary = try await container.resolve(TestService.self, name: "secondary")
//
//        XCTAssertTrue(primary is MockService)
//        XCTAssertTrue(secondary is ActorService)
//    }
//
//    func testAsyncFactoryRegistration() async throws {
//        // Test async factory registration
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ async throws in
//                ActorService()
//            }
//
//        let service = try await container.resolve(TestService.self, name: nil)
//        XCTAssertNotNil(service)
//        XCTAssertTrue(service is ActorService)
//    }
//
//    // MARK: - Retention Policy Tests
//
//    func testTransientRetention() async throws {
//        // Test transient dependency creation
//        _ = container.register(TestService.self)
//            .asTransient()
//            .with { _ in MockService() }
//
//        let service1 = try await container.resolve(TestService.self, name: nil) as! MockService
//        let service2 = try await container.resolve(TestService.self, name: nil) as! MockService
//
//        XCTAssertTrue(service1 !== service2)
//    }
//
//    func testSingletonRetention() async throws {
//        // Test singleton dependency creation
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ in MockService() }
//
//        let service1 = try await container.resolve(TestService.self, name: nil) as! MockService
//        let service2 = try await container.resolve(TestService.self, name: nil) as! MockService
//
//        XCTAssertTrue(service1 === service2)
//    }
//
//    func testWeakRetention() async throws {
//        // Test weak dependency retention
//        _ = container.register(TestService.self)
//            .asWeak()
//            .with { _ in MockService() }
//
//        weak var weakRef: MockService?
//
//        do {
//            let service = try await container.resolve(TestService.self, name: nil) as! MockService
//            weakRef = service
//            XCTAssertNotNil(weakRef)
//        }
//
//        // Force garbage collection
//        await Task.yield()
//        XCTAssertNil(weakRef)
//    }
//
//    // MARK: - Error Handling Tests
//
//    func testDependencyNotRegistered() async {
//        // Test error when dependency is not registered
//        do {
//            _ = try await container.resolve(TestService.self, name: nil)
//            XCTFail("Should have thrown dependencyNotRegistered error")
//        } catch let error as ContainerError {
//            switch error {
//            case .dependencyNotRegistered(let key):
//                XCTAssertTrue(key.represents(TestService.self))
//            default:
//                XCTFail("Wrong error type: \(error)")
//            }
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//
//    func testCircularDependencyDetection() async {
//        // Test circular dependency detection
//        _ = container.register(TestService.self)
//            .with { container in
//                _ = try await container.resolve(TestRepository.self, name: nil)
//                return MockService()
//            }
//
//        _ = container.register(TestRepository.self)
//            .with { container in
//                _ = try await container.resolve(TestService.self, name: nil)
//                return MockRepository()
//            }
//
//        do {
//            _ = try await container.resolve(TestService.self, name: nil)
//            XCTFail("Should have thrown circularDependency error")
//        } catch let error as ContainerError {
//            switch error {
//            case .circularDependency(let key, let path):
//                XCTAssertFalse(path.isEmpty)
//                XCTAssertTrue(key.represents(TestService.self) || key.represents(TestRepository.self))
//            default:
//                XCTFail("Wrong error type: \(error)")
//            }
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//
//    func testFactoryErrorHandling() async {
//        // Test factory error propagation
//        _ = container.register(TestService.self)
//            .with { _ in
//                throw NSError(domain: "TestError", code: 1, userInfo: nil)
//            }
//
//        do {
//            _ = try await container.resolve(TestService.self, name: nil)
//            XCTFail("Should have thrown factoryFailed error")
//        } catch let error as ContainerError {
//            switch error {
//            case .factoryFailed(let key, let underlyingError):
//                XCTAssertTrue(key.represents(TestService.self))
//                XCTAssertNotNil(underlyingError)
//            default:
//                XCTFail("Wrong error type: \(error)")
//            }
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//
//    // MARK: - Container Lifecycle Tests
//
//    func testUnregister() async throws {
//        // Test dependency unregistration
//        _ = container.register(TestService.self)
//            .with { _ in MockService() }
//
//        let service1 = try await container.resolve(TestService.self, name: nil)
//        XCTAssertNotNil(service1)
//
//        _ = container.unregister(TestService.self, name: nil)
//
//        do {
//            _ = try await container.resolve(TestService.self, name: nil)
//            XCTFail("Should have thrown dependencyNotRegistered error")
//        } catch is ContainerError {
//            // Expected
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//
//    func testReset() async throws {
//        // Test container reset functionality
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ in MockService() }
//
//        _ = try await container.resolve(TestService.self, name: nil)
//
//        await container.reset(ignoreDependencies: [])
//
//        do {
//            _ = try await container.resolve(TestService.self, name: nil)
//            XCTFail("Should have thrown dependencyNotRegistered error")
//        } catch is ContainerError {
//            // Expected
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//
//    func testResetWithIgnoredDependencies() async throws {
//        // Test reset with ignored dependencies
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ in MockService() }
//
//        _ = container.register(TestRepository.self)
//            .asSingleton()
//            .with { _ in MockRepository() }
//
//        let service = try await container.resolve(TestService.self, name: nil) as! MockService
//        _ = try await container.resolve(TestRepository.self, name: nil)
//
//        await container.reset(ignoreDependencies: [TestService.self])
//
//        // TestService should still be registered
//        let service2 = try await container.resolve(TestService.self, name: nil) as! MockService
//        XCTAssertTrue(service === service2)
//
//        // TestRepository should be unregistered
//        do {
//            _ = try await container.resolve(TestRepository.self, name: nil)
//            XCTFail("Should have thrown dependencyNotRegistered error")
//        } catch is ContainerError {
//            // Expected
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//
//    // MARK: - Advanced Features Tests
//
//    func testResolveAll() async throws {
//        // Test resolving all instances of a type
//        _ = container.register(TestService.self)
//            .named("service1")
//            .asSingleton()
//            .with { _ in MockService() }
//
//        _ = container.register(TestService.self)
//            .named("service2")
//            .asSingleton()
//            .with { _ in ActorService() }
//
//        // Resolve to instantiate
//        _ = try await container.resolve(TestService.self, name: "service1")
//        _ = try await container.resolve(TestService.self, name: "service2")
//
//        let allServices = await container.resolveAll(TestService.self)
//        XCTAssertEqual(allServices.count, 2)
//    }
//
//    func testFactoryRegistration() async throws {
//        // Test factory registration
//        let factory = ServiceFactory()
//        _ = container.registerFactory(factory)
//
//        let resolvedFactory = try await container.resolve(ServiceFactory.self, name: nil)
//        XCTAssertNotNil(resolvedFactory)
//    }
//}
//
//// MARK: - DIContainer Tests
//
//class DIContainerTests: XCTestCase {
//
//    override func setUp() async throws {
//        // Reset DIContainer to clean state
//        await DIContainer.setContainer(Container())
//    }
//
//    func testSharedInstance() async {
//        // Test singleton access
//        XCTAssertNotNil(DIContainer.shared)
//        XCTAssertTrue(DIContainer.shared === DIContainer.shared)
//    }
//
//    func testCurrentContainer() async throws {
//        // Test current container access
//        let container = await DIContainer.current
//        XCTAssertNotNil(container)
//    }
//
//    func testCurrentSyncContainer() {
//        // Test synchronous container access
//        let container = DIContainer.currentSync
//        XCTAssertNotNil(container)
//    }
//
//    func testSetContainer() async throws {
//        // Test setting a new container
//        let newContainer = Container()
//        await DIContainer.setContainer(newContainer)
//
//        let current = await DIContainer.current
//        // Note: We can't test identity since ContainerProtocol is a protocol
//        XCTAssertNotNil(current)
//    }
//
//    func testWithContainer() async throws {
//        // Test temporary container switching
//        _ = await DIContainer.current
//        let tempContainer = Container()
//
//        let result = await DIContainer.withContainer(tempContainer) {
//            let current = await DIContainer.current
//            // Note: We can't test identity since ContainerProtocol is a protocol
//            return current != nil
//        }
//
//        XCTAssertTrue(result)
//
//        // Verify original container is restored
//        let restoredContainer = await DIContainer.current
//        XCTAssertNotNil(restoredContainer)
//    }
//
//    func testScopedContainers() async throws {
//        // Test scoped container management
//        let scopedContainer = Container()
//        await DIContainer.setScopedContainer(scopedContainer, for: "testScope")
//
//        let retrieved = await DIContainer.scopedContainer(for: "testScope")
//        XCTAssertNotNil(retrieved)
//
//        await DIContainer.removeScopedContainer(for: "testScope")
//        let removed = await DIContainer.scopedContainer(for: "testScope")
//        XCTAssertNil(removed)
//    }
//
//    func testSetupMainContainer() async throws {
//        // Test main container setup
//        await DIContainer.setupMainContainer()
//
//        let container = await DIContainer.current
//        XCTAssertNotNil(container)
//    }
//
//    func testCreateMockContainer() async throws {
//        // Test mock container creation
//        let mockContainer = await DIContainer.createMockContainer()
//        XCTAssertNotNil(mockContainer)
//    }
//}
//
//// MARK: - Injected Property Wrapper Tests
//
//class InjectedTests: XCTestCase {
//    private var container: Container!
//
//    override func setUp() async throws {
//        container = Container()
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ in MockService() }
//
//        await DIContainer.setContainer(container)
//    }
//
//    func testBasicInjection() async throws {
//        // Test basic property wrapper injection
//        class TestClass {
//            @Injected var service: TestService
//        }
//
//        let instance = TestClass()
//        XCTAssertNotNil(instance.service)
//    }
//
//    func testNamedInjection() async throws {
//        // Test named dependency injection
//        _ = container.register(TestService.self)
//            .named("test")
//            .with { _ in ActorService() }
//
//        class TestClass {
//            @Injected(name: "test") var service: TestService
//        }
//
//        let instance = TestClass()
//        XCTAssertTrue(instance.service is ActorService)
//    }
//
//    func testLazyInjection() async throws {
//        // Test lazy injection behavior
//        var factoryCalled = false
//
//        _ = container.register(TestRepository.self)
//            .with { _ in
//                factoryCalled = true
//                return MockRepository()
//            }
//
//        class TestClass {
//            @Injected(lazy: true) var repository: TestRepository
//        }
//
//        let instance = TestClass()
//        XCTAssertFalse(factoryCalled)
//
//        _ = instance.repository
//        XCTAssertTrue(factoryCalled)
//    }
//
//    func testEagerInjection() async throws {
//        // Test eager injection behavior
//        var factoryCalled = false
//
//        _ = container.register(TestRepository.self)
//            .with { _ in
//                factoryCalled = true
//                return MockRepository()
//            }
//
//        class TestClass {
//            @Injected(lazy: false) var repository: TestRepository
//        }
//
//        _ = TestClass()
//        // Wait for async initialization
//        await Task.yield()
//        XCTAssertTrue(factoryCalled)
//    }
//
//    func testErrorStrategies() async throws {
//        // Test different error handling strategies
//        class TestClassWithThrow {
//            @Injected(errorStrategy: .throw) var unknownService: TestRepository
//        }
//
//        class TestClassWithDefault {
//            @Injected(errorStrategy: .useDefault(MockRepository())) var unknownService: TestRepository
//        }
//
//        // Test throw strategy - we can't actually test the fatalError
//        _ = TestClassWithThrow()
//
//        // Test default strategy
//        let defaultInstance = TestClassWithDefault()
//        XCTAssertNotNil(defaultInstance.unknownService)
//    }
//
//    func testReset() async throws {
//        // Test injection reset functionality
//        class TestClass {
//            @Injected var service: TestService
//        }
//
//        let instance = TestClass()
//        _ = instance.service // Trigger resolution
//
//        instance.$service.reset()
//        // After reset, service should be re-resolved on next access
//        XCTAssertNotNil(instance.service)
//    }
//
//    func testOptionalInjection() async throws {
//        // Test optional dependency injection
//        class TestClass {
//            @InjectedOptional var unknownService: TestRepository?
//        }
//
//        let instance = TestClass()
//        XCTAssertNil(instance.unknownService)
//    }
//
//    func testAsyncResolve() async throws {
//        // Test async resolution method
//        class TestClass {
//            @Injected var service: TestService
//        }
//
//        let instance = TestClass()
//        let service = try await instance.$service.resolve()
//        XCTAssertNotNil(service)
//    }
//}
//
//// MARK: - TypeKey Tests
//
//class TypeKeyTests: XCTestCase {
//
//    func testBasicTypeKey() {
//        // Test basic TypeKey creation
//        let key1 = TypeKey(TestService.self)
//        let key2 = TypeKey(TestService.self)
//
//        XCTAssertEqual(key1, key2)
//        XCTAssertEqual(key1.hashValue, key2.hashValue)
//    }
//
//    func testNamedTypeKey() {
//        // Test named TypeKey creation
//        let key1 = TypeKey(TestService.self, name: "primary")
//        let key2 = TypeKey(TestService.self, name: "primary")
//        let key3 = TypeKey(TestService.self, name: "secondary")
//
//        XCTAssertEqual(key1, key2)
//        XCTAssertNotEqual(key1, key3)
//    }
//
//    func testTypeKeyDescription() {
//        // Test TypeKey string representation
//        let key1 = TypeKey(TestService.self)
//        let key2 = TypeKey(TestService.self, name: "test")
//
//        XCTAssertTrue(key1.description.contains("TestService"))
//        XCTAssertTrue(key2.description.contains("TestService"))
//        XCTAssertTrue(key2.description.contains("test"))
//    }
//
//    func testTypeKeyRepresentation() {
//        // Test type representation check
//        let key = TypeKey(TestService.self)
//
//        XCTAssertTrue(key.represents(TestService.self))
//        XCTAssertFalse(key.represents(TestRepository.self))
//    }
//
//    func testTypeKeyCache() {
//        // Test TypeKey caching mechanism
//        let key1 = TypeKey.forType(TestService.self)
//        let key2 = TypeKey.forType(TestService.self)
//
//        XCTAssertEqual(key1, key2)
//    }
//
//    func testTypeKeyCodable() throws {
//        // Test TypeKey encoding/decoding
//        let key = TypeKey(TestService.self, name: "test")
//
//        let encoder = JSONEncoder()
//        let data = try encoder.encode(key)
//
//        let decoder = JSONDecoder()
//        let decodedKey = try decoder.decode(TypeKey.self, from: data)
//
//        XCTAssertEqual(key.description, decodedKey.description)
//    }
//}
//
//// MARK: - Factory Tests
//
//class FactoryTests: XCTestCase {
//    private var container: Container!
//
//    override func setUp() async throws {
//        container = Container()
//    }
//
//    func testSyncFactory() async throws {
//        // Test synchronous factory
//        let factory = ServiceFactory()
//        _ = container.register(ServiceFactory.self)
//            .asSingleton()
//            .with { _ in factory }
//
//        let product = try await container.create(factoryType: ServiceFactory.self, with: "test", name: nil)
//        XCTAssertNotNil(product)
//    }
//
//    func testAsyncFactory() async throws {
//        // Test asynchronous factory
//        let factory = AsyncServiceFactory()
//        _ = container.register(AsyncServiceFactory.self)
//            .asSingleton()
//            .with { _ in factory }
//
//        let product = try await container.createAsync(factoryType: AsyncServiceFactory.self, with: "test", name: nil)
//        XCTAssertNotNil(product)
//    }
//
//    func testSimpleFactory() async throws {
//        // Test simple factory without parameters
//        let factory = SimpleServiceFactory()
//        _ = container.register(SimpleServiceFactory.self)
//            .asSingleton()
//            .with { _ in factory }
//
//        let product = try await container.create(factoryType: SimpleServiceFactory.self, name: nil)
//        XCTAssertNotNil(product)
//    }
//
//    func testAsyncSimpleFactory() async throws {
//        // Test async simple factory without parameters
//        let factory = AsyncSimpleServiceFactory()
//        _ = container.register(AsyncSimpleServiceFactory.self)
//            .asSingleton()
//            .with { _ in factory }
//
//        let product = try await container.createAsync(factoryType: AsyncSimpleServiceFactory.self, name: nil)
//        XCTAssertNotNil(product)
//    }
//
//    func testFactoryWithVoidParams() async throws {
//        // Test factory with Void parameters (should work as SimpleFactory)
//        struct VoidParamFactory: Factory, SimpleFactory {
//            typealias Product = MockService
//            typealias Params = Void
//
//            func create(with params: Void) -> MockService {
//                return MockService()
//            }
//        }
//
//        let factory = VoidParamFactory()
//        _ = container.register(VoidParamFactory.self)
//            .asSingleton()
//            .with { _ in factory }
//
//        // Should be able to call without parameters
//        let product1 = try await container.create(factoryType: VoidParamFactory.self, with: (), name: nil)
//        let product2 = try await container.create(factoryType: VoidParamFactory.self, name: nil)
//
//        XCTAssertNotNil(product1)
//        XCTAssertNotNil(product2)
//    }
//}
//
//// MARK: - DIInjectable Tests
//
//class DIInjectableTests: XCTestCase {
//    private var container: Container!
//
//    override func setUp() async throws {
//        container = Container()
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ in MockService() }
//
//        await DIContainer.setContainer(container)
//    }
//
//    func testDIInjectableCreate() async throws {
//        // Test DIInjectable creation with current container
//        let service = try await InjectableService.create()
//        XCTAssertNotNil(service)
//        XCTAssertNotNil(service.testService)
//    }
//
//    func testDIInjectableCreateWithContainer() async throws {
//        // Test DIInjectable creation with custom container
//        let service = try InjectableService.create(with: container)
//        XCTAssertNotNil(service)
//        XCTAssertNotNil(service.testService)
//    }
//
//    func testDIViewModelBase() async throws {
//        // Test ViewModel base class
//        let viewModel = try await TestViewModel.create()
//        XCTAssertNotNil(viewModel)
//        XCTAssertNotNil(viewModel.service)
//    }
//
//    func testDIInjectableError() async {
//        // Test error when container is unavailable
//        await DIContainer.setContainer(Container())
//
//        do {
//            _ = try await InjectableService.create()
//            XCTFail("Should have thrown containerUnavailable error")
//        } catch let error as ContainerError {
//            switch error {
//            case .containerUnavailable:
//                break
//            default:
//                XCTFail("Wrong error type: \(error)")
//            }
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//}
//
//// MARK: - DependencyScope Tests
//
//class DependencyScopeTests: XCTestCase {
//
//    func testScopeLifecycle() async throws {
//        // Test scope setup and cleanup
//        let scope = TestScope(scopeId: "testScope")
//
//        XCTAssertFalse(scope.isSetup)
//        XCTAssertFalse(scope.isCleanedUp)
//
//        await scope.register()
//        XCTAssertTrue(scope.isSetup)
//
//        await scope.unregister()
//        XCTAssertTrue(scope.isCleanedUp)
//    }
//
//    func testScopeContainer() async throws {
//        // Test scope container access
//        let scope = TestScope(scopeId: "testScope")
//        await scope.register()
//
//        let container = try await scope.getContainer()
//        XCTAssertNotNil(container)
//    }
//
//    func testScopeContainerNotFound() async {
//        // Test error when scope container is not found
//        let scope = TestScope(scopeId: "nonexistentScope")
//
//        do {
//            _ = try await scope.getContainer()
//            XCTFail("Should have thrown scopeNotFound error")
//        } catch let error as ContainerError {
//            switch error {
//            case .scopeNotFound(let scopeId):
//                XCTAssertEqual(scopeId, "nonexistentScope")
//            default:
//                XCTFail("Wrong error type: \(error)")
//            }
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//    }
//
//    func testWithContainer() async throws {
//        // Test executing actions with scope container
//        let scope = TestScope(scopeId: "testScope")
//        await scope.register()
//
//        let result = try await scope.withContainer { container in
//            // Register a test service
//            _ = container.register(TestService.self)
//                .with { _ in MockService() }
//
//            return try await container.resolve(TestService.self, name: nil)
//        }
//
//        XCTAssertNotNil(result)
//    }
//}
//
//// MARK: - Error Tests
//
//class ErrorTests: XCTestCase {
//
//    func testContainerErrorDescriptions() {
//        // Test error descriptions for debugging
//        let key = TypeKey(TestService.self, name: "test")
//
//        let errors: [ContainerError] = [
//            .dependencyNotRegistered(key),
//            .circularDependency(key, path: [key]),
//            .invalidTypeReturned(expected: key, actual: String.self),
//            .containerUnavailable,
//            .scopeNotFound("testScope"),
//            .typeCastFailed(key, String.self),
//            .factoryFailed(key, underlyingError: NSError(domain: "test", code: 1))
//        ]
//
//        for error in errors {
//            XCTAssertNotNil(error.errorDescription)
//            XCTAssertFalse(error.errorDescription!.isEmpty)
//        }
//    }
//}
//
//// MARK: - Integration Tests
//
//class IntegrationTests: XCTestCase {
//
//    func testCompleteWorkflow() async throws {
//        // Test complete DI workflow
//        let container = Container()
//
//        // Register dependencies
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ in MockService() }
//
//        _ = container.register(TestRepository.self)
//            .with { container in
//                _ = try await container.resolve(TestService.self, name: nil)
//                return MockRepository()
//            }
//
//        // Set global container
//        await DIContainer.setContainer(container)
//
//        // Test injection
//        class TestController {
//            @Injected var service: TestService
//            @Injected var repository: TestRepository
//        }
//
//        let controller = TestController()
//        XCTAssertNotNil(controller.service)
//        XCTAssertNotNil(controller.repository)
//
//        // Test resolution
//        let resolvedService = try await container.resolve(TestService.self, name: nil) as! MockService
//        let injectedService = controller.service as! MockService
//        XCTAssertTrue(resolvedService === injectedService)
//    }
//
//    func testConcurrency() async throws {
//        // Test concurrent access to container
//        let container = Container()
//        _ = container.register(TestService.self)
//            .asSingleton()
//            .with { _ in MockService() }
//
//        await DIContainer.setContainer(container)
//
//        // Create multiple tasks accessing the container concurrently
//        let tasks = (0..<10).map { _ in
//            Task {
//                return try await container.resolve(TestService.self, name: nil)
//            }
//        }
//
//        let results = try await withThrowingTaskGroup(of: TestService.self) { group in
//            for task in tasks {
//                group.addTask {
//                    try await task.value
//                }
//            }
//
//            var services: [TestService] = []
//            for try await service in group {
//                services.append(service)
//            }
//            return services
//        }
//
//        // All should be the same singleton instance
//        XCTAssertEqual(results.count, 10)
//        let mockServices = results.compactMap { $0 as? MockService }
//        XCTAssertEqual(mockServices.count, 10)
//
//        for i in 1..<mockServices.count {
//            XCTAssertTrue(mockServices[0] === mockServices[i])
//        }
//    }
//
//    func testMemoryManagement() async throws {
//        // Test memory management of weak references
//        let container = Container()
//
//        weak var weakService: MockService?
//
//        // Register as weak
//        _ = container.register(TestService.self)
//            .asWeak()
//            .with { _ in MockService() }
//
//        do {
//            let service = try await container.resolve(TestService.self, name: nil) as! MockService
//            weakService = service
//            XCTAssertNotNil(weakService)
//        }
//
//        // Force garbage collection
//        await Task.yield()
//
//        // Weak reference should be nil
//        XCTAssertNil(weakService)
//    }
//}
//
//// MARK: - Test Extensions
//
//extension XCTestCase {
//    /// Helper to wait for async conditions
//    func waitForCondition(timeout: TimeInterval = 1.0, condition: @escaping () async -> Bool) async {
//        let deadline = Date().addingTimeInterval(timeout)
//        while Date() < deadline {
//            if await condition() {
//                return
//            }
//            await Task.yield()
//        }
//    }
//}
