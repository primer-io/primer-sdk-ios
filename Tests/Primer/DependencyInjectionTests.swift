//
//  DependencyInjectionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Dummy types for testing

protocol TestService: AnyObject {}
class TestServiceImpl: TestService {}
class AnotherServiceImpl: TestService {}

protocol DummyProtocol {}
class DummyImpl: DummyProtocol {}

enum DummyError: Error, Equatable {
    case boom
}

// MARK: - Dummy DependencyScope

/// Implements DependencyScope for testing scope registration/unregistration
@available(iOS 15.0, *)
class DummyScope: DependencyScope {
    let scopeId: String
    init(id: String) { self.scopeId = id }

    // no-op
    func cleanupScope() async {}

    // We override register() to build & register ON our local container
    func register() async {
        let container = Container()
        _ = try? await container.register(TestService.self)
            .asSingleton()
            .with { _ in TestServiceImpl() }
        await DIContainer.setScopedContainer(container, for: scopeId)
    }

    // We don’t even need setupContainer() any more
    func setupContainer() async {}
}

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

@available(iOS 15.0, *)
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
    func testWeakPolicyCachesInstance_concreteClass() async throws {
        let container = Container()
        // Register the concrete class for weak retention
        _ = try await container.register(TestServiceImpl.self)
            .asWeak()
            .with { _ in TestServiceImpl() }

        // Keep a strong reference in `first`
        let first  = try await container.resolve(TestServiceImpl.self)
        let second = try await container.resolve(TestServiceImpl.self)

        // Now the same instance should be returned
        XCTAssertTrue((first as AnyObject) === (second as AnyObject))
    }

    func testWeakPolicyDropsInstanceAfterRelease() async throws {
        let container = Container()
        _ = try await container.register(TestServiceImpl.self)
            .asWeak()
            .with { _ in TestServiceImpl() }

        // 1) Resolve and keep a strong reference
        var strongInstance: TestServiceImpl? = try await container.resolve(TestServiceImpl.self)
        weak var maybeWeak = strongInstance
        XCTAssertNotNil(maybeWeak, "The weak box should still point to the live instance")

        // 2) Drop the only strong reference
        strongInstance = nil
        // let ARC run
        await Task.yield()

        // at this point, the old instance should be gone
        XCTAssertNil(maybeWeak, "After dropping strongInstance, the weak ref should be nil")

        // 3) A new resolve produces a fresh instance
        let newInstance = try await container.resolve(TestServiceImpl.self)
        XCTAssertNotNil(newInstance)
        XCTAssertFalse(newInstance === maybeWeak, "Should get a brand-new instance after the old one died")
    }

    func testUnregisterRemovesRegistration() async {
        let container = Container()
        _ = try? await container.register(TestService.self)
            .asSingleton()
            .with { _ in TestServiceImpl() }

         _ = await container.unregister(TestService.self)

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
        await MainActor.run {
            XCTAssertTrue(DIContainer.currentSync! as AnyObject === newContainer as AnyObject)
        }
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

    // MARK: - WeakUnsupported for Non-Class Types

    func testWeakUnsupportedForNonClass() async {
        let container = Container()
        do {
            // Attempt to register Int as weak → unsupported
            _ = try await container.register(Int.self).asWeak()
                .with { _ in 42 }
            XCTFail("Expected weakUnsupported error")
        } catch let ContainerError.weakUnsupported(key) {
            XCTAssertTrue(key.represents(Int.self))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Factory Failure Wrapping

    func testFactoryFailedWrapsUnderlyingError() async {
        let container = Container()
        // Register a factory that always throws DummyError.boom
        _ = try? await container.register(TestService.self).asSingleton()
            .with { _ in throw DummyError.boom }

        do {
            _ = try await container.resolve(TestService.self)
            XCTFail("Expected factoryFailed error")
        } catch let ContainerError.factoryFailed(key, underlying) {
            XCTAssertTrue(underlying is DummyError)
            XCTAssertTrue(key.represents(TestService.self))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - DependencyScope Lifecycle

    func testDependencyScopeLifecycle() async throws {
        let scope = DummyScope(id: "scope1")

        // Before register: getContainer() throws scopeNotFound
        do {
            _ = try await scope.getContainer()
            XCTFail("Expected scopeNotFound error")
        } catch let ContainerError.scopeNotFound(id, _) {
            XCTAssertEqual(id, "scope1")
        }

        // Register the scope
        await scope.register()
        // Now getContainer() returns a ContainerProtocol
        let scopedContainer = try await scope.getContainer()
        let resolved = try await scopedContainer.resolve(TestService.self)
        XCTAssertTrue(resolved is TestServiceImpl)

        // withContainer should execute action in that scope
        let result = try await scope.withContainer { cont in
            let _ = try await cont.resolve(TestService.self)
            return "ok"
        }
        XCTAssertEqual(result, "ok")

        // Unregister and ensure getContainer() again fails
        await scope.unregister()
        do {
            _ = try await scope.getContainer()
            XCTFail("Expected scopeNotFound after unregister")
        } catch let ContainerError.scopeNotFound(id, _) {
            XCTAssertEqual(id, "scope1")
        }
    }

    // MARK: - DIContainer.withContainer Context Restoration

    func testDIContainerWithContainerRestoresOriginal() async throws {
        // Capture original before swap (may be nil if no container was set)
        let original = await DIContainer.current
        let temp = Container()

        // Swap in `temp`, run assertions inside, then swap back
        let ret = await DIContainer.withContainer(temp) {
            // ⬇️ Fetch current before asserting
            let inside = await DIContainer.current
            XCTAssertTrue(inside! as AnyObject === temp as AnyObject)
            return "done"
        }
        XCTAssertEqual(ret, "done")

        // After the block, make sure the original was restored
        let outside = await DIContainer.current

        // Handle the case where original might be nil (no container was set initially)
        if let originalContainer = original, let outsideContainer = outside {
            XCTAssertTrue(outsideContainer as AnyObject === originalContainer as AnyObject)
        } else {
            // Both should be nil if original was nil
            XCTAssertNil(original, "Original was not nil but outside is nil")
            XCTAssertNil(outside, "Outside is not nil but original was nil")
        }
    }

    // MARK: - Container Diagnostics & Health Checks

    func testContainerDiagnosticsAndHealth() async throws {
        let container = Container()
        // Register one singleton and one weak service
        _ = try await container.register(TestService.self).asSingleton()
            .with { _ in TestServiceImpl() }
        _ = try await container.register(AnotherServiceImpl.self).asWeak()
            .with { _ in AnotherServiceImpl() }

        // Resolve and keep references alive
        let strongService = try await container.resolve(TestService.self)
        let weakService   = try await container.resolve(AnotherServiceImpl.self)

        // (Use them in a no-op so compiler doesn't warn)
        XCTAssertNotNil(strongService)
        XCTAssertNotNil(weakService)

        // Now diagnostics will see one weak box with an active instance
        let diag = await container.getDiagnostics()
        XCTAssertEqual(diag.totalRegistrations, 2)
        XCTAssertEqual(diag.singletonInstances, 1)
        XCTAssertEqual(diag.weakReferences, 1)
        XCTAssertEqual(diag.activeWeakReferences, 1)
        XCTAssertTrue(diag.registeredTypes.contains(where: { $0.represents(TestService.self) }))

        // Health should be healthy
        let report = await container.performHealthCheck()
        XCTAssertEqual(report.status, .healthy)
        XCTAssertTrue(report.issues.isEmpty)
        XCTAssertTrue(report.recommendations.isEmpty)

        // And your existing “orphanedRegistrations” check stays the same…
    }

    // MARK: - InstrumentedContainer Metrics Recording

    func testInstrumentedContainerRecordsMetrics() async throws {
        actor TestMetrics: ContainerMetrics {
            private var resolutions: [(TypeKey, TimeInterval)] = []

            func recordResolution(for key: TypeKey, duration: TimeInterval) async {
                resolutions.append((key, duration))
            }
            func recordRegistration(for key: TypeKey) async {}
            func recordCacheHit(for key: TypeKey) async {}
            func recordCacheMiss(for key: TypeKey) async {}
            func getMetrics() async -> ContainerPerformanceMetrics {
                .init(
                    totalResolutions: resolutions.count,
                    averageResolutionTime: 0,
                    slowestResolutions: [],
                    cacheHitRate: 0,
                    memoryUsageEstimate: 0
                )
            }
            func recordedCount() async -> Int {
                resolutions.count
            }
        }

        let metrics = TestMetrics()
        let container = InstrumentedContainer(metrics: metrics, logger: { _ in })

        // Register & resolve a service
        _ = try await container.register(TestService.self).asSingleton()
            .with { _ in TestServiceImpl() }
        _ = try await container.resolve(TestService.self)

        // Assert via the public metrics API...
        let perf = await container.getPerformanceMetrics()
        XCTAssertEqual(perf?.totalResolutions, 1)

        // ...and via our helper to ensure recordResolution ran exactly once
        let count = await metrics.recordedCount()
        XCTAssertEqual(count, 1)
    }
}
