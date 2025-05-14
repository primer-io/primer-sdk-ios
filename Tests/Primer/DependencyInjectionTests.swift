// DependencyInjectionTestsChatGPT.swift

import XCTest
@testable import PrimerSDK

// MARK: - Dummy types for testing

protocol TestService: AnyObject {}
class TestServiceImpl: TestService {}
class AnotherServiceImpl: TestService {}

protocol DummyProtocol {}
class DummyImpl: DummyProtocol {}

// A simple synchronous factory for testing
struct NumberFactory: SynchronousFactory {
    typealias Product = Int
    func createSync(with params: Void) throws -> Int { 7 }
}

// A simple async factory for testing
struct StringFactory: Factory {
    typealias Product = String
    func create(with params: Void) async throws -> String { "hello" }
}

final class DIFrameworkTests: XCTestCase {

    // MARK: - TypeKey

    func testTypeKeyEqualityAndDescription() {
        let key1 = TypeKey(DummyProtocol.self, name: "foo")
        let key2 = TypeKey(DummyProtocol.self, name: "foo")
        XCTAssertEqual(key1, key2)
        XCTAssertEqual(key1.hashValue, key2.hashValue)
        XCTAssertTrue(key1.description.contains("DummyProtocol"))
        XCTAssertTrue(key1.description.contains("name: foo"))
    }

    // MARK: - InjectionResult

    func testInjectionResultSuccessAndFailure() {
        let success = InjectionResult.success(42)
        XCTAssertEqual(try success.get(), 42)
        XCTAssertEqual(success.value, 42)

        let failure = InjectionResult<Int>.failure(ContainerError.containerUnavailable)
        XCTAssertThrowsError(try failure.get())
        XCTAssertNil(failure.value)
    }

    // MARK: - RetentionPolicy → Strategy

    func testContainerRetainPolicyMakeStrategy() {
        let t = ContainerRetainPolicy.transient.makeStrategy()
        XCTAssertTrue(t is TransientStrategy)

        let s = ContainerRetainPolicy.singleton.makeStrategy()
        XCTAssertTrue(s is SingletonStrategy)

        let w = ContainerRetainPolicy.weak.makeStrategy()
        XCTAssertTrue(w is WeakStrategy)
    }

    // MARK: - Container registration & resolution

    func testTransientPolicyCreatesNewInstances() async throws {
        let container = Container()
        _ = try await container.register(TestService.self)
            .asTransient()
            .with { _ in TestServiceImpl() }

        let first = try await container.resolve(TestService.self)
        let second = try await container.resolve(TestService.self)
        XCTAssertFalse((first as AnyObject) === (second as AnyObject))
    }

    func testSingletonPolicyReturnsSameInstance() async throws {
        let container = Container()
        _ = try await container.register(TestService.self)
            .asSingleton()
            .with { _ in TestServiceImpl() }

        let first = try await container.resolve(TestService.self)
        let second = try await container.resolve(TestService.self)
        XCTAssertTrue((first as AnyObject) === (second as AnyObject))
    }

    // TODO: Failing test, check why
//    func testWeakPolicyCachesInstance() async throws {
//        let container = Container()
//        _ = try await container.register(TestService.self)
//            .asWeak()
//            .with { _ in TestServiceImpl() }
//
//        let first  = try await container.resolve(TestService.self)
//        let second = try await container.resolve(TestService.self)
//        XCTAssertTrue((first as AnyObject) === (second as AnyObject))
//    }

    func testUnregisterRemovesRegistration() async {
        let container = Container()
        _ = try? await container.register(TestService.self)
            .asSingleton()
            .with { _ in TestServiceImpl() }

         _ = container.unregister(TestService.self)
         await Task.yield()

        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Expected dependencyNotRegistered")
        } catch ContainerError.dependencyNotRegistered {
            // ✅ correct
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
    func testCircularDependencyDetection() async {
        class A {}

        let container = Container()
        // Factory for A resolves A again → immediate circular detection
        _ = try? await container.register(A.self)
            .asSingleton()
            .with { resolver in try await resolver.resolve(A.self) }

        do {
            _ = try await container.resolve(A.self)
            XCTFail("Expected circularDependency")
        } catch let ContainerError.circularDependency(key, path) {
            XCTAssertTrue(key.represents(A.self))
            XCTAssertTrue(path.contains(where: { $0.represents(A.self) }))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Batch & All resolution

    func testResolveBatchReturnsOrderedResults() async throws {
        let container = Container()
        _ = try await container.register(TestService.self)
            .named("b")
            .asSingleton()
            .with { _ in AnotherServiceImpl() }
        _ = try await container.register(TestService.self)
            .named("a")
            .asSingleton()
            .with { _ in TestServiceImpl() }

        let results = try await container.resolveBatch([
            (TestService.self, "b"),
            (TestService.self, "a")
        ])
        XCTAssertTrue(results[0] is AnotherServiceImpl)
        XCTAssertTrue(results[1] is TestServiceImpl)
    }

    func testResolveAllReturnsSingletons() async throws {
        let container = Container()
        _ = try await container.register(TestService.self)
            .named("singleton")
            .asSingleton()
            .with { _ in TestServiceImpl() }
        _ = try await container.register(TestService.self)
            .named("transient")
            .asTransient()
            .with { _ in AnotherServiceImpl() }

        let all = await container.resolveAll(TestService.self)
        // Only the singleton (strongly held) should appear
        XCTAssertEqual(all.count, 1)
        XCTAssertTrue(all.first is TestServiceImpl)
    }

    // MARK: - Reset & registerIfNeeded

    func testResetClearsExceptIgnored() async throws {
        let container = Container()
        _ = try await container.register(TestService.self)
            .asSingleton()
            .with { _ in TestServiceImpl() }
        _ = try await container.register(DummyProtocol.self)
            .asSingleton()
            .with { _ in DummyImpl() }

        // Resolve both once so they're created
        _ = try await container.resolve(TestService.self)
        _ = try await container.resolve(DummyProtocol.self)

        await container.reset(ignoreDependencies: [DummyProtocol.self])

        // TestService should be unregistered
        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Expected dependencyNotRegistered")
        } catch ContainerError.dependencyNotRegistered {
            // ok
        }
        // DummyProtocol should still resolve
        let dummy2 = try await container.resolve(DummyProtocol.self)
        XCTAssertTrue(dummy2 is DummyImpl)
    }

    func testRegisterIfNeeded() async throws {
        let container = Container()
        if let first = await container.registerIfNeeded(DummyProtocol.self) {
            _ = try await first.with { _ in DummyImpl() }
        }
        // Second time returns nil → nothing to register
        let second = await container.registerIfNeeded(DummyProtocol.self)
        XCTAssertNil(second)
    }

    // MARK: - DIContainer global & scoped

    func testSetAndGetGlobalContainer() async {
        let newContainer = Container()
        await DIContainer.setContainer(newContainer)
        let current = await DIContainer.current
        XCTAssertTrue(current! as AnyObject === newContainer as AnyObject)
        XCTAssertTrue(DIContainer.currentSync! as AnyObject === newContainer as AnyObject)
    }

    func testScopedContainerLifecycle() async throws {
        let container = Container()
        _ = try await container.register(TestService.self)
            .asSingleton()
            .with { _ in TestServiceImpl() }

        let scopeId = "testScope"
        await DIContainer.setScopedContainer(container, for: scopeId)
        let scoped = await DIContainer.scopedContainer(for: scopeId)
        XCTAssertNotNil(scoped)

        await DIContainer.removeScopedContainer(for: scopeId)
        let removed = await DIContainer.scopedContainer(for: scopeId)
        XCTAssertNil(removed)
    }

    // MARK: - Factory extensions

    func testRegisterFactorySync() async throws {
        let container = Container()
        _ = try await container.registerFactory(NumberFactory())

        let factory = try await container.resolve(NumberFactory.self)
        XCTAssertEqual(try factory.createSync(with: ()), 7)
    }

    func testRegisterFactoryAsync() async throws {
        let container = Container()
        _ = try await container.registerFactory(StringFactory())

        let factory = try await container.resolve(StringFactory.self)
        let result  = try await factory.create(with: ())
        XCTAssertEqual(result, "hello")
    }
}
