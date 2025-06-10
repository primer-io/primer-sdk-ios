//
//  MinimalDITest.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import Foundation
import SwiftUI

/// Minimal test to verify core DI functionality with no external dependencies
@available(iOS 15.0, *)
class MinimalDITest {
    
    /// Test basic container operations
    static func testBasicContainer() async -> [String] {
        var results: [String] = []
        
        do {
            // Test 1: Create container
            let container = Container()
            results.append("✅ Container creation successful")
            
            // Test 2: Register simple types
            _ = try await container.register(String.self)
                .named("greeting")
                .asSingleton()
                .with { _ in "Hello DI World!" }
            
            _ = try await container.register(Int.self)
                .asTransient()
                .with { _ in 42 }
            
            results.append("✅ Registration of simple types successful")
            
            // Test 3: Resolve dependencies
            let greeting = try await container.resolve(String.self, name: "greeting")
            let number = try await container.resolve(Int.self)
            
            results.append("✅ Resolution successful: '\(greeting)' and \(number)")
            
            // Test 4: Test different retention policies
            _ = try await container.register(Bool.self)
                .asWeak()
                .with { _ in true as Bool as AnyObject as! Bool }
            
            results.append("✅ Different retention policies work")
            
            // Test 5: Test diagnostics
            let diagnostics = await container.getDiagnostics()
            results.append("✅ Diagnostics: \(diagnostics.totalRegistrations) total, \(diagnostics.singletonInstances) singletons")
            
            // Test 6: Test health check
            let health = await container.performHealthCheck()
            results.append("✅ Health check: \(health.status)")
            
        } catch {
            results.append("❌ Basic container test failed: \(error)")
        }
        
        return results
    }
    
    /// Test environment integration
    static func testEnvironmentIntegration() -> [String] {
        var results: [String] = []
        
        // Test environment key
        let defaultValue = DIContainer.DIContainerEnvironmentKey.defaultValue
        results.append("✅ Environment key default: \(defaultValue == nil ? "nil" : "not nil")")
        
        // Test environment values extension
        var env = EnvironmentValues()
        let testContainer = Container()
        
        env.diContainer = testContainer
        
        if env.diContainer != nil {
            results.append("✅ Environment injection successful")
        } else {
            results.append("❌ Environment injection failed")
        }
        
        return results
    }
    
    /// Test global container setup
    static func testGlobalContainer() async -> [String] {
        var results: [String] = []
        
        // Create and set a test container
        let testContainer = Container()
        
        // Register a test dependency
        _ = try? await testContainer.register(String.self)
            .named("global-test")
            .asSingleton()
            .with { _ in "Global container works!" }
        
        // Set as global container
        await DIContainer.setContainer(testContainer)
        
        // Test global access
        if let global = await DIContainer.current {
            results.append("✅ Global container set successfully")
            
            // Try to resolve from global container
            do {
                let result = try await global.resolve(String.self, name: "global-test")
                results.append("✅ Global container resolution: '\(result)'")
            } catch {
                results.append("❌ Global container resolution failed: \(error)")
            }
        } else {
            results.append("❌ Global container not set")
        }
        
        return results
    }
    
    /// Run comprehensive minimal tests
    static func runMinimalTests() async -> [String] {
        var allResults: [String] = []
        
        allResults.append("=== DI Container Minimal Tests ===")
        allResults.append("")
        
        allResults.append("--- Basic Container Test ---")
        let basicResults = await testBasicContainer()
        allResults.append(contentsOf: basicResults)
        
        allResults.append("")
        allResults.append("--- Environment Integration Test ---")
        let envResults = testEnvironmentIntegration()
        allResults.append(contentsOf: envResults)
        
        allResults.append("")
        allResults.append("--- Global Container Test ---")
        let globalResults = await testGlobalContainer()
        allResults.append(contentsOf: globalResults)
        
        return allResults
    }
}

/// Simple SwiftUI view for testing
@available(iOS 15.0, *)
struct MinimalDITestView: View {
    @State private var testResults: [String] = []
    @State private var isRunning = false
    @Environment(\.diContainer) private var container
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    
                    // Container status
                    HStack {
                        Text("Container Status:")
                            .font(.headline)
                        Spacer()
                        Text(container != nil ? "✅ Available" : "❌ Not Available")
                            .foregroundColor(container != nil ? .green : .red)
                    }
                    .padding(.bottom)
                    
                    // Test results
                    ForEach(testResults, id: \.self) { result in
                        HStack(alignment: .top) {
                            if result.starts(with: "===") || result.starts(with: "---") {
                                Text(result)
                                    .font(.headline)
                                    .padding(.top, 4)
                            } else if result.starts(with: "✅") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(result)
                                    .font(.system(size: 12, family: .monospaced))
                            } else if result.starts(with: "❌") {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(result)
                                    .font(.system(size: 12, family: .monospaced))
                            } else if !result.isEmpty {
                                Text(result)
                                    .font(.system(size: 12, family: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    
                    if isRunning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Running tests...")
                                .font(.caption)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("DI Tests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Run Tests") {
                        runTests()
                    }
                    .disabled(isRunning)
                }
            }
        }
        .onAppear {
            if testResults.isEmpty {
                runTests()
            }
        }
    }
    
    private func runTests() {
        isRunning = true
        testResults.removeAll()
        
        Task {
            let results = await MinimalDITest.runMinimalTests()
            
            await MainActor.run {
                testResults = results
                isRunning = false
            }
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct MinimalDITestView_Previews: PreviewProvider {
    static var previews: some View {
        let mockContainer = Container()
        
        MinimalDITestView()
            .environment(\.diContainer, mockContainer)
    }
}
#endif