//
//  BasicDITest.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import Foundation
import SwiftUI

/// Basic test to verify DI container functionality without external dependencies
@available(iOS 15.0, *)
class BasicDITest {
    
    /// Test basic container creation and registration
    static func testBasicContainerFunctionality() async -> [String] {
        var results: [String] = []
        
        // Test 1: Create container
        do {
            let container = Container()
            results.append("✅ Container creation successful")
            
            // Test 2: Register a simple dependency
            _ = try await container.register(String.self)
                .named("test")
                .asSingleton()
                .with { _ in "Hello DI!" }
            
            results.append("✅ Basic registration successful")
            
            // Test 3: Resolve the dependency
            let resolved = try await container.resolve(String.self, name: "test")
            if resolved == "Hello DI!" {
                results.append("✅ Basic resolution successful: '\(resolved)'")
            } else {
                results.append("❌ Resolution returned wrong value: '\(resolved)'")
            }
            
            // Test 4: Test diagnostics
            let diagnostics = await container.getDiagnostics()
            results.append("✅ Diagnostics successful: \(diagnostics.totalRegistrations) registrations")
            
        } catch {
            results.append("❌ Basic container test failed: \(error)")
        }
        
        return results
    }
    
    /// Test CompositionRoot setup
    static func testCompositionRootSetup() async -> [String] {
        var results: [String] = []
        
        do {
            // Test CompositionRoot.configure()
            await CompositionRoot.configure()
            results.append("✅ CompositionRoot.configure() completed")
            
            // Test global container access
            if let globalContainer = await DIContainer.current {
                results.append("✅ Global DIContainer.current is available")
                
                // Test some basic resolutions that should work
                if let container = globalContainer as? Container {
                    let diagnostics = await container.getDiagnostics()
                    results.append("✅ Global container has \(diagnostics.totalRegistrations) registrations")
                }
                
            } else {
                results.append("❌ Global DIContainer.current is nil")
            }
            
        } catch {
            results.append("❌ CompositionRoot setup failed: \(error)")
        }
        
        return results
    }
    
    /// Test environment integration
    static func testEnvironmentIntegration() -> [String] {
        var results: [String] = []
        
        // Test environment key existence
        let defaultValue = DIContainer.DIContainerEnvironmentKey.defaultValue
        if defaultValue == nil {
            results.append("✅ Environment key has correct default value (nil)")
        } else {
            results.append("❌ Environment key has unexpected default value")
        }
        
        // Test creating a test container for environment
        let testContainer = Container()
        
        // Create mock environment values
        var mockEnvironment = EnvironmentValues()
        mockEnvironment.diContainer = testContainer
        
        if mockEnvironment.diContainer != nil {
            results.append("✅ Environment injection works")
        } else {
            results.append("❌ Environment injection failed")
        }
        
        return results
    }
    
    /// Run all tests
    static func runAllTests() async -> [String] {
        var allResults: [String] = []
        
        allResults.append("=== Basic Container Test ===")
        let basicResults = await testBasicContainerFunctionality()
        allResults.append(contentsOf: basicResults)
        
        allResults.append("")
        allResults.append("=== CompositionRoot Test ===")
        let compositionResults = await testCompositionRootSetup()
        allResults.append(contentsOf: compositionResults)
        
        allResults.append("")
        allResults.append("=== Environment Integration Test ===")
        let envResults = testEnvironmentIntegration()
        allResults.append(contentsOf: envResults)
        
        return allResults
    }
}

/// Simple test view that can be used in previews or debug builds
@available(iOS 15.0, *)
struct BasicDITestView: View {
    @State private var testResults: [String] = []
    @State private var isRunning = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DI Container Basic Tests")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Button("Run Tests") {
                        runTests()
                    }
                    .disabled(isRunning)
                }
                
                if isRunning {
                    ProgressView("Running tests...")
                        .padding()
                }
                
                ForEach(testResults, id: \.self) { result in
                    HStack(alignment: .top) {
                        if result.starts(with: "===") {
                            Text(result)
                                .font(.headline)
                                .padding(.top, 8)
                        } else if result.starts(with: "✅") {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(result)
                                .font(.caption)
                        } else if result.starts(with: "❌") {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(result)
                                .font(.caption)
                        } else if result.isEmpty {
                            Spacer()
                                .frame(height: 4)
                        } else {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding()
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
            let results = await BasicDITest.runAllTests()
            
            await MainActor.run {
                testResults = results
                isRunning = false
            }
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct BasicDITestView_Previews: PreviewProvider {
    static var previews: some View {
        BasicDITestView()
    }
}
#endif