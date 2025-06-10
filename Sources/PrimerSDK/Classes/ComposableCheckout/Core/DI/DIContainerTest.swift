//
//  DIContainerTest.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import SwiftUI

/// Simple test view to verify DI container functionality
@available(iOS 15.0, *)
struct DIContainerTestView: View {
    @Environment(\.diContainer) private var container
    @State private var testResults: [String] = []
    @State private var isTestComplete = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DI Container Test")
                .font(.title2)
                .bold()
            
            if isTestComplete {
                ForEach(testResults, id: \.self) { result in
                    HStack {
                        Image(systemName: result.contains("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.contains("✅") ? .green : .red)
                        Text(result)
                            .font(.caption)
                    }
                }
            } else {
                ProgressView("Running DI tests...")
            }
            
            Button("Run Tests") {
                runTests()
            }
            .disabled(isTestComplete)
        }
        .padding()
        .onAppear {
            if !isTestComplete {
                runTests()
            }
        }
    }
    
    private func runTests() {
        testResults.removeAll()
        
        Task {
            await testContainerAvailability()
            await testDependencyResolution()
            await testCompositionRootSetup()
            
            await MainActor.run {
                isTestComplete = true
            }
        }
    }
    
    @MainActor
    private func testContainerAvailability() async {
        if container != nil {
            testResults.append("✅ DI Container is available in environment")
        } else {
            testResults.append("❌ DI Container is NOT available in environment")
        }
    }
    
    @MainActor
    private func testDependencyResolution() async {
        guard let container = container else {
            testResults.append("❌ Cannot test resolution - no container")
            return
        }
        
        // Test ValidationService resolution
        do {
            let validationService = try container.resolveSync(ValidationService.self)
            testResults.append("✅ ValidationService resolved successfully: \(type(of: validationService))")
        } catch {
            testResults.append("❌ ValidationService resolution failed: \(error)")
        }
        
        // Test RulesFactory resolution
        do {
            let rulesFactory = try container.resolveSync(RulesFactory.self)
            testResults.append("✅ RulesFactory resolved successfully: \(type(of: rulesFactory))")
        } catch {
            testResults.append("❌ RulesFactory resolution failed: \(error)")
        }
        
        // Test DesignTokensManager resolution
        do {
            let tokensManager = try container.resolveSync(DesignTokensManager.self)
            testResults.append("✅ DesignTokensManager resolved successfully: \(type(of: tokensManager))")
        } catch {
            testResults.append("❌ DesignTokensManager resolution failed: \(error)")
        }
        
        // Test TaskManager resolution
        do {
            let taskManager = try container.resolveSync(TaskManager.self)
            testResults.append("✅ TaskManager resolved successfully: \(type(of: taskManager))")
        } catch {
            testResults.append("❌ TaskManager resolution failed: \(error)")
        }
        
        // Test CardNumberValidator resolution
        do {
            let validator = try container.resolveSync(CardNumberValidator.self)
            testResults.append("✅ CardNumberValidator resolved successfully: \(type(of: validator))")
        } catch {
            testResults.append("❌ CardNumberValidator resolution failed: \(error)")
        }
    }
    
    @MainActor
    private func testCompositionRootSetup() async {
        // Test global container setup
        let globalContainer = await DIContainer.current
        if globalContainer != nil {
            testResults.append("✅ Global DIContainer.current is set")
        } else {
            testResults.append("❌ Global DIContainer.current is nil")
        }
        
        // Test container diagnostics
        if let container = container as? Container {
            let diagnostics = await container.getDiagnostics()
            testResults.append("✅ Container diagnostics: \(diagnostics.totalRegistrations) registrations")
            testResults.append("   - Singletons: \(diagnostics.singletonInstances)")
            testResults.append("   - Weak refs: \(diagnostics.weakReferences)")
            
            // Test health check
            let health = await container.performHealthCheck()
            let status = health.status == .healthy ? "✅ Healthy" : "⚠️ Has issues"
            testResults.append("   - Health: \(status)")
        }
    }
}

/// Preview for testing
@available(iOS 15.0, *)
struct DIContainerTestView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock container for preview
        let mockContainer = Container()
        
        DIContainerTestView()
            .environment(\.diContainer, mockContainer)
            .task {
                // Register some basic dependencies for preview
                _ = try? await mockContainer.register(DesignTokensManager.self)
                    .asSingleton()
                    .with { _ in DesignTokensManager() }
            }
    }
}