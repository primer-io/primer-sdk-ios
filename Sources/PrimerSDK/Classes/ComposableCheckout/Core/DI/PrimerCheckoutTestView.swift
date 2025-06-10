//
//  PrimerCheckoutTestView.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import SwiftUI

/// Test view that simulates PrimerCheckout usage for DI testing
@available(iOS 15.0, *)
struct PrimerCheckoutTestView: View {
    @State private var testResults: [String] = []
    @State private var containerInitialized = false
    @State private var diContainer: (any ContainerProtocol)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Header
                VStack {
                    Text("PrimerCheckout DI Test")
                        .font(.title2)
                        .bold()
                    
                    Text("Testing end-to-end DI container setup")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Container status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Container Status")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(containerInitialized ? Color.green : Color.orange)
                            .frame(width: 12, height: 12)
                        
                        Text(containerInitialized ? "Initialized" : "Initializing...")
                            .font(.caption)
                    }
                    
                    if let container = diContainer {
                        Text("Container Type: \(type(of: container))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Test results
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Test Results")
                            .font(.headline)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(testResults, id: \.self) { result in
                                    HStack {
                                        if result.starts(with: "✅") {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else if result.starts(with: "❌") {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        } else if result.starts(with: "⚠️") {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Text(result)
                                            .font(.caption)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Manual test button
                Button("Run DI Tests") {
                    runContainerTests()
                }
                .buttonStyle(.borderedProminent)
                
            }
            .padding()
            .navigationTitle("DI Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.diContainer, diContainer)
        .onAppear {
            setupContainer()
        }
    }
    
    private func setupContainer() {
        testResults.append("⚠️ Starting container setup...")
        
        Task {
            do {
                // Simulate CompositionRoot.configure()
                let container = Container()
                
                // Register some basic dependencies
                _ = try await container.register(String.self)
                    .named("app-name")
                    .asSingleton()
                    .with { _ in "PrimerSDK ComposableCheckout" }
                
                _ = try await container.register(Int.self)
                    .named("version")
                    .asSingleton()
                    .with { _ in 1 }
                
                // Set global container
                await DIContainer.setContainer(container)
                
                await MainActor.run {
                    diContainer = container
                    containerInitialized = true
                    testResults.append("✅ Container setup completed")
                    
                    // Run initial tests
                    runContainerTests()
                }
                
            } catch {
                await MainActor.run {
                    testResults.append("❌ Container setup failed: \(error)")
                }
            }
        }
    }
    
    private func runContainerTests() {
        guard let container = diContainer else {
            testResults.append("❌ No container available for testing")
            return
        }
        
        Task {
            var newResults: [String] = []
            
            // Test 1: Basic resolution
            do {
                let appName = try await container.resolve(String.self, name: "app-name")
                newResults.append("✅ Resolved app name: '\(appName)'")
            } catch {
                newResults.append("❌ Failed to resolve app name: \(error)")
            }
            
            // Test 2: Sync resolution (for SwiftUI)
            do {
                let version = try container.resolveSync(Int.self, name: "version")
                newResults.append("✅ Sync resolution works: version \(version)")
            } catch {
                newResults.append("❌ Sync resolution failed: \(error)")
            }
            
            // Test 3: Environment access
            if let _ = diContainer {
                newResults.append("✅ Container accessible in environment")
            } else {
                newResults.append("❌ Container not accessible in environment")
            }
            
            // Test 4: Diagnostics
            if let concreteContainer = container as? Container {
                let diagnostics = await concreteContainer.getDiagnostics()
                newResults.append("✅ Diagnostics: \(diagnostics.totalRegistrations) deps registered")
                
                let health = await concreteContainer.performHealthCheck()
                newResults.append("✅ Health check: \(health.status)")
            }
            
            await MainActor.run {
                testResults.append(contentsOf: newResults)
            }
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct PrimerCheckoutTestView_Previews: PreviewProvider {
    static var previews: some View {
        PrimerCheckoutTestView()
    }
}
#endif