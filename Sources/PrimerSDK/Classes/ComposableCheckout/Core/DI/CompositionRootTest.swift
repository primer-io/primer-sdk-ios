//
//  CompositionRootTest.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import Foundation

/// Test version of CompositionRoot with only verified dependencies
@available(iOS 15.0, *)
class CompositionRootTest {
    
    /// Configure a test container with only dependencies we know exist
    static func configureTestContainer() async -> (Container, [String]) {
        let container = Container()
        var results: [String] = []
        
        // Register basic infrastructure that we know works
        await registerBasicInfrastructure(in: container, results: &results)
        
        // Set as global container
        await DIContainer.setContainer(container)
        results.append("✅ Set as global container")
        
        return (container, results)
    }
    
    /// Register only basic infrastructure dependencies
    private static func registerBasicInfrastructure(in container: Container, results: inout [String]) async {
        
        // Register simple mock dependencies that we can control
        do {
            _ = try await container.register(String.self)
                .named("sdk-name")
                .asSingleton()
                .with { _ in "PrimerSDK ComposableCheckout" }
            results.append("✅ Registered SDK name")
            
            _ = try await container.register(String.self)
                .named("version")
                .asSingleton()
                .with { _ in "1.0.0" }
            results.append("✅ Registered version")
            
            // Test dependency injection with resolver
            _ = try await container.register(String.self)
                .named("full-name")
                .asSingleton()
                .with { resolver in
                    let name = try await resolver.resolve(String.self, name: "sdk-name")
                    let version = try await resolver.resolve(String.self, name: "version")
                    return "\(name) v\(version)"
                }
            results.append("✅ Registered dependent service")
            
            // Test different retention policies
            _ = try await container.register(Bool.self)
                .named("feature-flag")
                .asTransient()
                .with { _ in true }
            results.append("✅ Registered transient dependency")
            
        } catch {
            results.append("❌ Infrastructure registration failed: \(error)")
        }
    }
    
    /// Test the container with comprehensive checks
    static func testContainer(_ container: Container) async -> [String] {
        var results: [String] = []
        
        // Test 1: Basic resolution
        do {
            let sdkName = try await container.resolve(String.self, name: "sdk-name")
            results.append("✅ Basic resolution: '\(sdkName)'")
        } catch {
            results.append("❌ Basic resolution failed: \(error)")
        }
        
        // Test 2: Dependent resolution
        do {
            let fullName = try await container.resolve(String.self, name: "full-name")
            results.append("✅ Dependent resolution: '\(fullName)'")
        } catch {
            results.append("❌ Dependent resolution failed: \(error)")
        }
        
        // Test 3: Transient resolution (multiple calls should work)
        do {
            let flag1 = try await container.resolve(Bool.self, name: "feature-flag")
            let flag2 = try await container.resolve(Bool.self, name: "feature-flag")
            results.append("✅ Transient resolution: \(flag1) and \(flag2)")
        } catch {
            results.append("❌ Transient resolution failed: \(error)")
        }
        
        // Test 4: Sync resolution
        do {
            let version = try container.resolveSync(String.self, name: "version")
            results.append("✅ Sync resolution: '\(version)'")
        } catch {
            results.append("❌ Sync resolution failed: \(error)")
        }
        
        // Test 5: Diagnostics
        let diagnostics = await container.getDiagnostics()
        results.append("✅ Diagnostics: \(diagnostics.totalRegistrations) total registrations")
        results.append("   - Singletons: \(diagnostics.singletonInstances)")
        results.append("   - Weak refs: \(diagnostics.weakReferences)")
        
        // Test 6: Health check
        let health = await container.performHealthCheck()
        results.append("✅ Health check: \(health.status)")
        if !health.issues.isEmpty {
            results.append("   - Issues: \(health.issues.count)")
        }
        
        // Test 7: Resolve all
        let allStrings = await container.resolveAll(String.self)
        results.append("✅ Resolve all strings: found \(allStrings.count)")
        
        return results
    }
    
    /// Run comprehensive CompositionRoot tests
    static func runCompositionRootTests() async -> [String] {
        var allResults: [String] = []
        
        allResults.append("=== CompositionRoot Test (Safe Dependencies) ===")
        allResults.append("")
        
        // Configure test container
        let (container, setupResults) = await configureTestContainer()
        allResults.append("--- Setup Results ---")
        allResults.append(contentsOf: setupResults)
        
        allResults.append("")
        allResults.append("--- Container Tests ---")
        let testResults = await testContainer(container)
        allResults.append(contentsOf: testResults)
        
        allResults.append("")
        allResults.append("--- Global Container Verification ---")
        
        // Test global container access
        if let global = await DIContainer.current {
            allResults.append("✅ Global container accessible")
            
            // Test that it's the same container
            do {
                let globalName = try await global.resolve(String.self, name: "sdk-name")
                allResults.append("✅ Global container works: '\(globalName)'")
            } catch {
                allResults.append("❌ Global container resolution failed: \(error)")
            }
        } else {
            allResults.append("❌ Global container not accessible")
        }
        
        return allResults
    }
}

/// Mock classes for testing if real ones don't exist
@available(iOS 15.0, *)
class MockValidationService {
    func validateCardNumber(_ number: String) -> Bool {
        return number.count >= 13 && number.count <= 19
    }
}

@available(iOS 15.0, *)
class MockDesignTokensManager {
    var currentTheme: String = "light"
}

@available(iOS 15.0, *)
class MockTaskManager {
    private var tasks: [String] = []
    
    func addTask(_ task: String) {
        tasks.append(task)
    }
    
    func getTasks() -> [String] {
        return tasks
    }
}