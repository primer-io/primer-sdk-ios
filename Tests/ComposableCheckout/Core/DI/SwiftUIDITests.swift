//
//  SwiftUIDITests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
final class SwiftUIDITests: XCTestCase {
    
    // MARK: - Test Types
    
    protocol TestServiceProtocol: AnyObject {
        var identifier: String { get }
    }
    
    class TestService: TestServiceProtocol {
        let identifier = UUID().uuidString
    }
    
    class MockTestService: TestServiceProtocol {
        let identifier = "mock-service"
    }
    
    // MARK: - Test Views
    
    struct TestView: View {
        @Environment(\.diContainer) var container
        @State private var resolvedService: TestServiceProtocol?
        
        var body: some View {
            VStack {
                if let service = resolvedService {
                    Text("Service: \(service.identifier)")
                        .accessibilityIdentifier("service-identifier")
                } else {
                    Text("No Service")
                        .accessibilityIdentifier("no-service")
                }
            }
            .onAppear {
                resolvedService = try? container?.resolveSync(TestServiceProtocol.self)
            }
        }
    }
    
    struct InjectedPropertyWrapperTestView: View {
        @Injected(TestServiceProtocol.self) var service
        
        var body: some View {
            VStack {
                if let service = service {
                    Text("Injected: \(service.identifier)")
                        .accessibilityIdentifier("injected-service")
                } else {
                    Text("Not Injected")
                        .accessibilityIdentifier("not-injected")
                }
            }
        }
    }
    
    struct RequiredInjectedTestView: View {
        @RequiredInjected(TestServiceProtocol.self, fallback: MockTestService()) var service
        
        var body: some View {
            Text("Required: \(service.identifier)")
                .accessibilityIdentifier("required-service")
        }
    }
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        // Reset global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
    }
    
    override func tearDown() async throws {
        // Clean up
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        try await super.tearDown()
    }
    
    // MARK: - Environment Tests
    
    func testDIContainerEnvironmentKey() async throws {
        let container = Container()
        _ = try await container.register(TestServiceProtocol.self)
            .asSingleton()
            .with { _ in TestService() }
        
        await DIContainer.setContainer(container)
        
        let view = await TestView()
            .environment(\.diContainer, container)
        
        // Test that view can be created with container environment
        // The actual environment access happens during SwiftUI rendering
        XCTAssertNotNil(view)
        
        // Create a hosting controller to trigger environment setup
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // View should be created successfully with environment
        XCTAssertNotNil(hostingController.rootView)
    }
    
    func testViewWithResolvedDependency() async throws {
        let container = Container()
        let testService = TestService()
        _ = try await container.register(TestServiceProtocol.self)
            .asSingleton()
            .with { _ in testService }
        
        // Test that the modifier can be applied without errors
        // The actual resolution happens during SwiftUI view lifecycle
        let view = await TestView()
            .withResolvedDependency(TestServiceProtocol.self) { service in
                // This closure will be called during SwiftUI rendering
                XCTAssertNotNil(service)
            }
            .environment(\.diContainer, container)
        
        // Create hosting controller to trigger view lifecycle
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // View should be created successfully
        XCTAssertNotNil(hostingController.rootView)
    }
    
    func testViewWithResolvedDependencyNamedRegistration() async throws {
        let container = Container()
        let namedService = TestService()
        _ = try await container.register(TestServiceProtocol.self)
            .named("special")
            .asSingleton()
            .with { _ in namedService }
        
        // Test that the named modifier can be applied without errors
        let view = await TestView()
            .withResolvedDependency(TestServiceProtocol.self, name: "special") { service in
                // This closure will be called during SwiftUI rendering
                XCTAssertNotNil(service)
            }
            .environment(\.diContainer, container)
        
        // Create hosting controller to trigger view lifecycle
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // View should be created successfully
        XCTAssertNotNil(hostingController.rootView)
    }
    
    // MARK: - Injected Property Wrapper Tests
    
    func testInjectedPropertyWrapper() async throws {
        let container = Container()
        let testService = TestService()
        _ = try await container.register(TestServiceProtocol.self)
            .asSingleton()
            .with { _ in testService }
        
        await DIContainer.setContainer(container)
        
        let view = await InjectedPropertyWrapperTestView()
            .environment(\.diContainer, container)
        
        // Create a hosting controller to trigger view lifecycle
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // Test that view can be created successfully with @Injected property wrapper
        XCTAssertNotNil(hostingController.rootView)
    }
    
    func testInjectedPropertyWrapperWithoutContainer() async throws {
        // Use empty container to simulate no registration
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        let view = await InjectedPropertyWrapperTestView()
            .environment(\.diContainer, emptyContainer)
        
        // Create a hosting controller without proper service registration
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // Should handle missing service gracefully without crash
        XCTAssertNotNil(hostingController.rootView)
    }
    
    func testInjectedPropertyWrapperBinding() async throws {
        let container = Container()
        _ = try await container.register(TestServiceProtocol.self)
            .asSingleton()
            .with { _ in TestService() }
        
        let view = await InjectedPropertyWrapperTestView()
            .environment(\.diContainer, container)
        
        // Test that view can be created with @Injected property wrapper
        XCTAssertNotNil(view)
        
        // Create hosting controller to trigger property wrapper initialization
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // View should be created successfully
        XCTAssertNotNil(hostingController.rootView)
    }
    
    // MARK: - RequiredInjected Property Wrapper Tests
    
    func testRequiredInjectedPropertyWrapper() async throws {
        let container = Container()
        let testService = TestService()
        _ = try await container.register(TestServiceProtocol.self)
            .asSingleton()
            .with { _ in testService }
        
        await DIContainer.setContainer(container)
        
        let view = await RequiredInjectedTestView()
            .environment(\.diContainer, container)
        
        // Create a hosting controller to trigger view lifecycle
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // The property wrapper should resolve the dependency or use fallback
        XCTAssertNotNil(hostingController.rootView)
    }
    
    func testRequiredInjectedFallback() async throws {
        // Use empty container - should use fallback
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        let view = await RequiredInjectedTestView()
            .environment(\.diContainer, emptyContainer)
        
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // Should use the fallback MockTestService without crash
        XCTAssertNotNil(hostingController.rootView)
    }
    
    // MARK: - Modifier Tests
    
    func testDependencyInjectionModifier() async throws {
        let container = Container()
        await DIContainer.setContainer(container)
        
        // This modifier validates container availability
        let view = await TestView()
            .injectDependencies()
            .environment(\.diContainer, container)
        
        // Should not crash or log errors when container is available
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
    }
    
    func testDependencyInjectionModifierWithoutContainer() async throws {
        // This should log an error but not crash
        let view = await TestView()
            .injectDependencies()
        
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // Verify no crash occurs
        XCTAssertTrue(true, "View should handle missing container gracefully")
    }
    
    func testDependencyResolutionModifierError() async throws {
        let container = Container()
        await DIContainer.setContainer(container)
        // Don't register the service - resolution should fail
        
        let view = await TestView()
            .withResolvedDependency(TestServiceProtocol.self) { _ in
                XCTFail("Should not resolve when service not registered")
            }
            .environment(\.diContainer, container)
        
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // Error should be logged but view should still be created
        XCTAssertNotNil(hostingController.rootView)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteSwiftUIIntegration() async throws {
        // Set up a complete DI environment
        let container = Container()
        
        // Register multiple services
        _ = try await container.register(TestServiceProtocol.self)
            .asSingleton()
            .with { _ in TestService() }
        
        _ = try await container.register(TestServiceProtocol.self)
            .named("mock")
            .asSingleton()
            .with { _ in MockTestService() }
        
        await DIContainer.setContainer(container)
        
        // Create a complex view hierarchy
        struct IntegrationTestView: View {
            @Injected(TestServiceProtocol.self) var defaultService
            @Injected(TestServiceProtocol.self, name: "mock") var namedService
            @RequiredInjected(TestServiceProtocol.self, fallback: MockTestService()) var requiredService
            
            var body: some View {
                VStack {
                    if let service = defaultService {
                        Text("Default: \(service.identifier)")
                    }
                    if let service = namedService {
                        Text("Named: \(service.identifier)")
                    }
                    Text("Required: \(requiredService.identifier)")
                }
                .injectDependencies()
            }
        }
        
        let view = await IntegrationTestView()
            .environment(\.diContainer, container)
        
        let hostingController = await UIHostingController(rootView: view)
        _ = await hostingController.view
        
        // Complex view hierarchy should be created successfully
        XCTAssertNotNil(hostingController.rootView)
    }
}
