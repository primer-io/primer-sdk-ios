// DIContainerUnitTests.swift
//
// Unit tests for the dependency injection framework.
//
// These tests cover registration and resolution of dependencies with different retention policies
// (transient, singleton, weak), error handling, factories (Factory and AsyncFactory), property
// wrapper injection (@Injected, @InjectedOptional), scoped containers (DependencyScope),
// ContainerError descriptions, TypeKey behavior, and container lifecycle methods.
// Each test function is asynchronous where necessary and verifies correct behavior or error throwing.
//
// Usage: Copy this file into your Xcode test target and run the tests.
//

import XCTest
@testable import PrimerSDK

@MainActor
final class DIContainerUnitTests: XCTestCase {
    private class Dummy {
        let id = UUID()
    }
    private class A { let b: B; init(b: B) { self.b = b } }
    private class B { let a: A; init(a: A) { self.a = a } }
    private protocol P {}
    private class Impl1: P {}
    private class Impl2: P {}

    func testTransientResolutionOfValueType() async throws {
        let container = Container(logger: { _ in })
        _ = container.register(Int.self).asTransient().with { _ in 42 }
        let first = try await container.resolve(Int.self)
        let second = try await container.resolve(Int.self)
        XCTAssertEqual(first, 42)
        XCTAssertEqual(second, 42)
    }

    func testTransientResolutionOfReferenceType() async throws {
        let container = Container(logger: { _ in })
        _ = container.register(Dummy.self).asTransient().with { _ in Dummy() }
        let first = try await container.resolve(Dummy.self)
        let second = try await container.resolve(Dummy.self)
        XCTAssertNotEqual(first.id, second.id)
    }

    func testSingletonResolution() async throws {
        let container = Container(logger: { _ in })
        _ = container.register(Dummy.self).asSingleton().with { _ in Dummy() }
        let first = try await container.resolve(Dummy.self)
        let second = try await container.resolve(Dummy.self)
        XCTAssertEqual(first.id, second.id)
    }

    func testWeakResolution() async throws {
        let container = Container(logger: { _ in })
        _ = container.register(Dummy.self).asWeak().with { _ in Dummy() }
        let first = try await container.resolve(Dummy.self)
        let second = try await container.resolve(Dummy.self)
        XCTAssertEqual(first.id, second.id)
    }

    func testUnregisteredDependencyThrows() async throws {
        let container = Container(logger: { _ in })
        container.unregister(Int.self, name: nil)
        do {
            _ = try await container.resolve(Int.self)
            XCTFail("Expected dependencyNotRegistered error")
        } catch let error as ContainerError {
            guard case .dependencyNotRegistered = error else {
                return XCTFail("Expected dependencyNotRegistered, got \(error)")
            }
        }
    }

    func testCircularDependencyThrows() async throws {
        let container = Container(logger: { _ in })
        _ = container.register(A.self).asTransient().with { resolver in A(b: try await resolver.resolve(B.self)) }
        _ = container.register(B.self).asTransient().with { resolver in B(a: try await resolver.resolve(A.self)) }
        do {
            _ = try await container.resolve(A.self)
            XCTFail("Expected circularDependency error")
        } catch let error as ContainerError {
            guard case .circularDependency = error else {
                return XCTFail("Expected circularDependency, got \(error)")
            }
        }
    }

    func testResolveAllSingletons() async {
        let container = Container(logger: { _ in })
        _ = container.register(P.self).named("one").asSingleton().with { _ in Impl1() }
        _ = container.register(P.self).named("two").asSingleton().with { _ in Impl2() }
        let all = await container.resolveAll(P.self)
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains { $0 is Impl1 })
        XCTAssertTrue(all.contains { $0 is Impl2 })
    }

    func testContainerErrorDescriptions() {
        let key = TypeKey(Int.self)
        let error = ContainerError.dependencyNotRegistered(key)
        XCTAssertEqual(error.localizedDescription, "Dependency not registered: \(key)")
    }

    func testTypeKeyEqualityAndDescription() {
        let key1 = TypeKey(String.self)
        let key2 = TypeKey(String.self)
        XCTAssertEqual(key1, key2)
        XCTAssertTrue(key1.represents(String.self))
        XCTAssertEqual(key1.description, String(reflecting: String.self))
    }

    func testFactoryResolution() async throws {
        struct SimpleFactoryImpl: SimpleFactory {
            func create() -> String { "hello" }
        }
        let container = Container(logger: { _ in })
        _ = container.register(SimpleFactoryImpl.self).asSingleton().with { _ in SimpleFactoryImpl() }
        let factory: SimpleFactoryImpl = try await container.resolve(SimpleFactoryImpl.self)
        XCTAssertEqual(factory.create(), "hello")
    }

    func testAsyncFactoryResolution() async throws {
        struct AsyncFactoryImpl: AsyncFactory {
            func create(with params: Int) async throws -> String { return String(params) }
            typealias Product = String
            typealias Params = Int
        }
        let container = Container(logger: { _ in })
        _ = container.register(AsyncFactoryImpl.self).asSingleton().with { _ in AsyncFactoryImpl() }
        let result: String = try await container.createAsync(factoryType: AsyncFactoryImpl.self, with: 5)
        XCTAssertEqual(result, "5")
    }

    func testDependencyScopeLifecycle() async throws {
        class TestScope: DependencyScope {
            let scopeId = "test"
            func setupContainer() async {
                let container = Container()
                _ = container.register(String.self).asSingleton().with { _ in "scoped" }
                await DIContainer.setScopedContainer(container, for: scopeId)
            }
            func cleanupScope() async {}
        }
        let scope = TestScope()
        await scope.register()
        let container = try await scope.getContainer()
        let value = try await container.resolve(String.self)
        XCTAssertEqual(value, "scoped")
        await scope.unregister()
        do {
            _ = try await scope.getContainer()
            XCTFail("Expected scopeNotFound error")
        } catch let error as ContainerError {
            guard case .scopeNotFound = error else { return XCTFail("Expected scopeNotFound, got \(error)") }
        }
    }

    func testCreateContainerCreatesDistinctInstances() {
        let c1 = DIContainer.createContainer() as! Container
        let c2 = DIContainer.createContainer() as! Container
        XCTAssertFalse(ObjectIdentifier(c1) == ObjectIdentifier(c2))
    }
}
