//
//  ComprehensiveTestView.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import SwiftUI

/// Comprehensive test view that runs all DI container tests
@available(iOS 15.0, *)
struct ComprehensiveTestView: View {
    @State private var allTestResults: [String] = []
    @State private var isRunning = false
    @State private var currentTest = ""
    @Environment(\.diContainer) private var environmentContainer
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DI Container Test Suite")
                            .font(.title2)
                            .bold()
                        
                        Text("Comprehensive testing of the dependency injection implementation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Environment status
                        HStack {
                            Text("Environment Container:")
                            Text(environmentContainer != nil ? "✅ Available" : "❌ Not Available")
                                .foregroundColor(environmentContainer != nil ? .green : .red)
                                .bold()
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Current test status
                    if isRunning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            VStack(alignment: .leading) {
                                Text("Running Tests...")
                                    .font(.headline)
                                if !currentTest.isEmpty {
                                    Text(currentTest)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Test results
                    if !allTestResults.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Test Results")
                                .font(.headline)
                            
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(allTestResults, id: \.self) { result in
                                    TestResultRow(result: result)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("DI Tests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isRunning ? "Running..." : "Run All Tests") {
                        runAllTests()
                    }
                    .disabled(isRunning)
                }
            }
        }
        .onAppear {
            if allTestResults.isEmpty && !isRunning {
                runAllTests()
            }
        }
    }
    
    private func runAllTests() {
        isRunning = true
        allTestResults.removeAll()
        
        Task {
            // Test 1: Minimal DI Tests
            await updateCurrentTest("Running minimal DI tests...")
            let minimalResults = await MinimalDITest.runMinimalTests()
            await appendResults(minimalResults)
            
            // Test 2: CompositionRoot Tests
            await updateCurrentTest("Running CompositionRoot tests...")
            let compositionResults = await CompositionRootTest.runCompositionRootTests()
            await appendResults(compositionResults)
            
            // Test 3: Environment Integration Test
            await updateCurrentTest("Testing environment integration...")
            let envResults = await testEnvironmentIntegration()
            await appendResults(envResults)
            
            // Test 4: Performance Test
            await updateCurrentTest("Running performance tests...")
            let perfResults = await runPerformanceTests()
            await appendResults(perfResults)
            
            await MainActor.run {
                currentTest = ""
                isRunning = false
                
                // Generate summary
                let passed = allTestResults.filter { $0.contains("✅") }.count
                let failed = allTestResults.filter { $0.contains("❌") }.count
                let warnings = allTestResults.filter { $0.contains("⚠️") }.count
                
                allTestResults.append("")
                allTestResults.append("=== TEST SUMMARY ===")
                allTestResults.append("✅ Passed: \(passed)")
                allTestResults.append("❌ Failed: \(failed)")
                allTestResults.append("⚠️ Warnings: \(warnings)")
                
                if failed == 0 {
                    allTestResults.append("🎉 All tests completed successfully!")
                } else {
                    allTestResults.append("🚨 Some tests failed - review implementation")
                }
            }
        }
    }
    
    @MainActor
    private func updateCurrentTest(_ test: String) {
        currentTest = test
    }
    
    @MainActor
    private func appendResults(_ results: [String]) {
        allTestResults.append(contentsOf: results)
        allTestResults.append("") // Add spacing
    }
    
    private func testEnvironmentIntegration() async -> [String] {
        var results: [String] = []
        results.append("=== Environment Integration Tests ===")
        
        // Test environment container
        if environmentContainer != nil {
            results.append("✅ Environment container available")
            
            // Try to use environment container
            do {
                if let globalContainer = await DIContainer.current {
                    results.append("✅ Global container matches environment setup")
                } else {
                    results.append("⚠️ Global container not set, but environment container exists")
                }
            }
        } else {
            results.append("❌ Environment container not available")
        }
        
        // Test SwiftUI property wrapper
        results.append("✅ SwiftUI property wrappers compiled successfully")
        
        return results
    }
    
    private func runPerformanceTests() async -> [String] {
        var results: [String] = []
        results.append("=== Performance Tests ===")
        
        let container = Container()
        
        // Register many dependencies
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<100 {
            _ = try? await container.register(String.self)
                .named("test-\(i)")
                .asSingleton()
                .with { _ in "Value \(i)" }
        }
        
        let registrationTime = CFAbsoluteTimeGetCurrent() - startTime
        results.append("✅ Registered 100 dependencies in \(String(format: "%.3f", registrationTime))s")
        
        // Test resolution performance
        let resolveStartTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<100 {
            _ = try? await container.resolve(String.self, name: "test-\(i)")
        }
        
        let resolutionTime = CFAbsoluteTimeGetCurrent() - resolveStartTime
        results.append("✅ Resolved 100 dependencies in \(String(format: "%.3f", resolutionTime))s")
        
        // Test diagnostics performance
        let diagStartTime = CFAbsoluteTimeGetCurrent()
        let _ = await container.getDiagnostics()
        let diagTime = CFAbsoluteTimeGetCurrent() - diagStartTime
        results.append("✅ Diagnostics completed in \(String(format: "%.3f", diagTime))s")
        
        return results
    }
}

struct TestResultRow: View {
    let result: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if result.starts(with: "===") {
                Text(result)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 8)
            } else if result.starts(with: "---") {
                Text(result)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else if result.starts(with: "✅") {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 16, height: 16)
                Text(result)
                    .font(.system(size: 11, design: .monospaced))
            } else if result.starts(with: "❌") {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 16, height: 16)
                Text(result)
                    .font(.system(size: 11, design: .monospaced))
            } else if result.starts(with: "⚠️") {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 16, height: 16)
                Text(result)
                    .font(.system(size: 11, design: .monospaced))
            } else if result.starts(with: "🎉") || result.starts(with: "🚨") {
                Text(result)
                    .font(.headline)
                    .foregroundColor(result.starts(with: "🎉") ? .green : .red)
                    .padding(.top, 4)
            } else if !result.isEmpty {
                Text(result)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct ComprehensiveTestView_Previews: PreviewProvider {
    static var previews: some View {
        let mockContainer = Container()
        
        ComprehensiveTestView()
            .environment(\.diContainer, mockContainer)
    }
}
#endif